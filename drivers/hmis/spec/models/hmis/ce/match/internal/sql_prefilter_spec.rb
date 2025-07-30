# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Internal::SqlPrefilter, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { Hmis::Ce::Match::Expression::FieldMap.new(current_date: current_date) }
  let(:pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: requirement_expression) }
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

    context 'with an expression that requires a join using DAYS_AGO' do
      let(:requirement_expression) { 'DAYS_AGO(last_enrolled_at) < 365' }

      before do
        [
          [client1, current_date - 6.months],  # Within 365 days
          [client2, current_date - 2.years],   # Outside 365 days
        ].each do |source_client, exit_date|
          ds = source_client.data_source
          project = create(:hmis_hud_project,  data_source: ds)
          enrollment = create(:hmis_hud_enrollment, client: source_client, data_source: ds, project: project, entry_date: exit_date - 1.week)
          create(:hmis_base_hud_exit, enrollment: enrollment, exit_date: exit_date, data_source: ds)
        end
      end

      it 'correctly filters clients based on joined table data' do
        result = prefilter.call(client_universe)
        expect(result.eligible_clients.pluck(:id)).to contain_exactly(destination_client1.id)
        expect(result.lost_eligibility_clients).to be_empty
      end
    end

    context 'with a last_enrolled_at expression using DAYS_AGO and a client with an open enrollment' do
      let(:requirement_expression) { 'DAYS_AGO(last_enrolled_at) < 30' }

      before do
        # client1 has an open enrollment, so should be included
        ds1 = client1.data_source
        project1 = create(:hmis_hud_project, data_source: ds1)
        create(:hmis_hud_enrollment, client: client1, data_source: ds1, project: project1, entry_date: current_date - 2.months)

        # client2 has a closed enrollment that does not meet the criteria (exited >30 days ago)
        ds2 = client2.data_source
        project2 = create(:hmis_hud_project, data_source: ds2)
        enrollment2 = create(:hmis_hud_enrollment, client: client2, data_source: ds2, project: project2, entry_date: current_date - 3.months)
        create(:hmis_base_hud_exit, enrollment: enrollment2, exit_date: current_date - 60.days, data_source: ds2)
      end

      it 'considers their last_enrolled_at as current date and includes them' do
        result = prefilter.call(client_universe)
        expect(result.eligible_clients.pluck(:id)).to contain_exactly(destination_client1.id)
        expect(result.lost_eligibility_clients).to be_empty
      end
    end
  end
end
