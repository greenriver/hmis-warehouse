###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared_contexts/hud_enrollment_builders'

RSpec.describe 'ProjectsController#show', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_projects: true, can_view_client_name: true, can_view_clients: true, can_upload_hud_zips: true) }
  let!(:project) { create_project(project_type: 1) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    source.destination_client
  end

  it 'lists every enrolled client when more clients than the preload miss threshold are enrolled' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    get project_path(project)

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
