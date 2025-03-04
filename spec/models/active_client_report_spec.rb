
require 'rails_helper'

RSpec.describe ActiveClientReport, type: :model do
    let(:today) { Date.current }
    let!(:data_source) { create :grda_warehouse_data_source, authoritative: true }
    let!(:wh_data_source) { create :grda_warehouse_data_source, source_type: nil, authoritative: false }
    let!(:organization) { create :hud_organization, data_source: data_source }

    let(:role) do
      create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true)
    end
    before do
      setup_access_control(user, role, Collection.system_collection(:data_sources))
    end

    let(:user) { create :acl_user}
    let!(:project) do
      create(
        :grda_warehouse_hud_project,
        organization: organization,
        project_type: 4,
        data_source: data_source,
      )
    end

    let(:days_homeless) { 30 }
    let!(:source_clients) do
      3.times.map do
        source_client = create :hud_client, data_source_id: data_source.id
        create :hud_enrollment, client: source_client, data_source: data_source, project: project, entry_date: today - days_homeless.days
        client = create(:hud_client, data_source: wh_data_source)
        create :warehouse_client, source_id: source_client.id, destination_id: client.id, data_source: data_source
        source_client
      end
    end
    let(:destination_clients) do
      source_clients.map(&:destination_client)
    end
    let(:filter) do
      params= {:on=>today, :start=>(today - 1.year), :end=>today, :comparison_pattern=>:no_comparison_period, :household_type=>:all}
      ::Filters::FilterBase.new(user_id: user.id).update(params)
    end
    let(:report) { described_class.new(filter:filter, user: user) }

    it 'passes a smoke test' do
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
      expect(report.enrollment_scope.size).to eq 3
    end
end
