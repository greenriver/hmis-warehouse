# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Internal::SqlPrefilter, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: requirement_expression) }
  let(:field_map) { Hmis::Ce::Match::Expression::FieldMap.new }
  let(:prefilter) { described_class.new(pool, field_map) }
  let!(:client1) { create(:hmis_hud_client, dob: 20.years.ago) } # age 20
  let!(:client2) { create(:hmis_hud_client, dob: 15.years.ago) } # age 15
  let(:destination_client1) { GrdaWarehouse::Hud::Client.find(client1.destination_client.id) }
  let(:destination_client2) { GrdaWarehouse::Hud::Client.find(client2.destination_client.id) }
  let(:client_universe) { GrdaWarehouse::Hud::Client.where(id: [destination_client1, destination_client2].map(&:id)) }

  before { GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! }

  describe '#call' do
    context 'with an age-based requirement' do
      let(:requirement_expression) { 'current_age > 18' }

      it 'filters the client universe to only include eligible clients' do
        result = prefilter.call(client_universe)
        expect(result.eligible_clients.pluck(:id)).to contain_exactly(client1.destination_client.id)
        expect(result.lost_eligibility_clients).to be_empty
      end
    end

    context 'when a client who was previously in the pool is no longer eligible' do
      let(:requirement_expression) { 'current_age > 25' }
      let(:proxy) { create(:hmis_ce_client_proxy, client: destination_client1) }

      it 'identifies the client who lost eligibility' do
        create(:hmis_ce_match_candidate, candidate_pool: pool, client_proxy: proxy)
        result = prefilter.call(client_universe)
        expect(result.eligible_clients).to be_empty
        expect(result.lost_eligibility_clients.pluck(:id)).to contain_exactly(destination_client1.id)
      end
    end

    context 'with an expression that cannot be translated to SQL' do
      let(:requirement_expression) { "INCLUDES(open_enrollment_project_types, PROJECT_TYPE('CE'))" }

      it 'returns the original client universe' do
        result = prefilter.call(client_universe)
        expect(result.eligible_clients.pluck(:id)).to contain_exactly(destination_client1.id, destination_client2.id)
        expect(result.lost_eligibility_clients).to be_empty
      end
    end
  end
end
