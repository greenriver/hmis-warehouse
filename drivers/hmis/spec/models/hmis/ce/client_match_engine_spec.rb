require 'rails_helper'

RSpec.describe Hmis::Ce::ClientMatch::Engine, type: :model do
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
  let(:eligibility_requirements) { nil }
  let(:prioritization_formula) { nil }
  let(:policy) { create(:hmis_ce_client_match_policy, eligibility_requirements: eligibility_requirements, prioritization_formula: prioritization_formula) }

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

  def generate_candidates(policy, clients)
    described_class.call(policy, clients)
    policy.candidates
  end

  describe 'Policy that is always false' do
    let(:eligibility_requirements) { '1=0' }
    it 'returns no candidates' do
      results = generate_candidates(policy, clients)
      expect(results).to be_empty
    end
  end

  describe 'Policy that is always true' do
    let(:eligibility_requirements) { '1=1' }
    it 'returns all candidates' do
      results = generate_candidates(policy, clients)
      expect(results.map(&:client_id).sort).to eq(clients.map(&:id).sort)
    end
  end

  describe 'Policy that evaluates age' do
    let(:eligibility_requirements) { 'current_age > 18' }
    it 'filters correctly' do
      results = generate_candidates(policy, clients)
      expect(results.map(&:client_id).sort).to eq(adult_clients.map(&:id).sort)
    end
  end

  describe 'Policy that evaluates age and veteran status' do
    let(:eligibility_requirements) { 'current_age >= 65 AND veteran_status = 1' }
    it 'filters correctly' do
      results = generate_candidates(policy, clients)
      expect(results.map(&:client_id).sort).to eq([client_senior_veteran.id])
    end
  end
end
