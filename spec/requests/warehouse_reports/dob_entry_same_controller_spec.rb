###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::DOBEntrySameController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'warehouse_reports/dob_entry_same', name: 'DOB Entry Same') }
  let!(:project) { create_project(project_type: 1) }
  let(:shared_date) { 1.year.ago.to_date }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage', dob: shared_date)
    create_enrollment(client: source, project: project, entry_date: shared_date)
    source.destination_client
  end

  it 'lists every client when more clients than the preload miss threshold have a DOB equal to their entry date' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get warehouse_reports_dob_entry_same_index_path

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
