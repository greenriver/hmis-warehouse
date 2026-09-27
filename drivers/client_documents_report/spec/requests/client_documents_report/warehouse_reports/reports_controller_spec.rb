###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'ClientDocumentsReport::WarehouseReports::ReportsController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'client_documents_report/warehouse_reports/reports', name: 'Client Documents Report') }
  let!(:project) { create_project(project_type: 1) }
  let!(:required_file_tag) do
    ActsAsTaggableOn::Tag.create!(name: 'Preload Coverage Tag')
    create(:available_file_tag, name: 'Preload Coverage Tag', group: 'Group')
    ActsAsTaggableOn::Tag.find_by!(name: 'Preload Coverage Tag')
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    source.destination_client
  end

  it 'lists every client when more clients than the preload miss threshold were served' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    get client_documents_report_warehouse_reports_reports_path(filters: { start: 3.months.ago.to_date, end: Date.current, project_ids: [project.id], required_files: [required_file_tag.id], require_service_during_range: false })

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
