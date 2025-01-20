require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Engine, type: :model do
  let(:user) { create(:hmis_user) }
  let(:opportunity) { create(:hmis_ce_opportunity, workflow_template: template) }
  let(:instance) { opportunity.workflow_template.instances.create! }
  let(:referral) { create(:hmis_ce_referral, opportunity: opportunity, workflow_instance: instance, referred_by: user) }
  let(:engine) { referral.workflow_engine }

  let(:client_adult_non_veteran) { create(:hmis_hud_client, veteran_status: 0, dob: 20.years.ago) }
  let(:client_minor_non_veteran) { create(:hmis_hud_client, veteran_status: 0, dob: 10.years.ago) }
  let(:client_adult_veteran) { create(:hmis_hud_client, veteran_status: 1, dob: 20.years.ago) }
  let(:client_senior_veteran) { create(:hmis_hud_client, veteran_status: 1, dob: 68.years.ago) }

  # override in tests
  let(:requirement_expression) { 'TRUE' }
  let(:priority_expression) { '0' }
  let(:pool) do
    create(
      :hmis_ce_match_candidate_pool,
      requirement_expression: requirement_expression,
      priority_expression: priority_expression,
    )
  end

  let(:clients) do
    Hmis::Hud::Client.where(id: [
      client_adult_non_veteran,
      client_minor_non_veteran,
      client_adult_veteran,
      client_senior_veteran,
    ].map(&:id))
  end

  let(:adult_clients) do
    clients - [client_minor_non_veteran]
  end

  def generate_candidates(pool, clients)
    described_class.call(pool, clients)
    pool.candidates
  end

  describe 'Policy that is always false' do
    let(:requirement_expression) { '1=0' }
    it 'returns no candidates' do
      results = generate_candidates(pool, clients)
      expect(results).to be_empty
    end
  end

  describe 'Policy that is always true' do
    let(:requirement_expression) { '1=1' }
    it 'returns all candidates' do
      results = generate_candidates(pool, clients)
      expect(results.map(&:client_id).sort).to eq(clients.map(&:id).sort)
    end
  end

  describe 'Policy that evaluates age' do
    let(:requirement_expression) { 'current_age > 18' }
    it 'filters correctly' do
      results = generate_candidates(pool, clients)
      expect(results.map(&:client_id).sort).to eq(adult_clients.map(&:id).sort)
    end
  end

  describe 'Policy that evaluates age and veteran status' do
    let(:requirement_expression) { 'current_age >= 65 AND veteran_status = 1' }
    it 'filters correctly' do
      results = generate_candidates(pool, clients)
      expect(results.map(&:client_id).sort).to eq([client_senior_veteran.id])
    end
  end
end
