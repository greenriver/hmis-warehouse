
require 'rails_helper'

RSpec.describe GrdaWarehouse::EnrollmentChangeHistory, type: :model do
  describe '.create_for_clients_on_date!' do
    let(:today ) { Date.current }
    let!(:data_source) { create :grda_warehouse_data_source }
    let!(:wh_data_source) { create :data_source_fixed_id }
    let!(:organization) { create :hud_organization, data_source: data_source }
    let!(:project) do
      create(
        :grda_warehouse_hud_project,
        organization: organization,
        project_type: HudUtility2024.residential_project_type_numbers_by_code[:es],
        data_source: data_source,
      )
    end

    let!(:clients) do
      5.times.map do
        source_client = create :hud_client, data_source_id: data_source.id
        enrollment =create :hud_enrollment, client: source_client, data_source: data_source, project: project, entry_date: (today - 30.days)
        client = create(:hud_client, data_source: wh_data_source)
        create :warehouse_client, source_id: source_client.id, destination_id: client.id, data_source: data_source
        source_client
      end
    end

    it 'passes a smoke test' do
      expect {
        described_class.create_for_clients_on_date!(client_ids: clients.map(&:id), date: today)
      }.to change(described_class, :count).by(5).and make_database_queries(count: 10..11)

      clients.map(&:reload)
      clients.each do |client|
        history = described_class.where(client_id: client.id).sole
        expect(history.on).to eq(today)
        # FIXME: not quite sure how to get the job to produce these
        #expect(history.residential).to eq(residential_enrollments.to_json)
        #expect(history.other).to eq(other_enrollments.to_json)
        #expect(history.days_homeless).to eq(days_homeless)
      end
    end
  end
end
