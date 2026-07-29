###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The Annual PATH Report queue form embeds a data-collection-path URL that the
# project picker POSTs back to /api/projects. That URL must scope projects with
# the same permission the queued report uses (:can_view_assigned_reports) and
# restrict to PATH project types and funder — for both permission schemes.
RSpec.describe 'HudPathReport paths#new project picker', type: :request, exclude_fixpoints: true do
  include AccessControlSetup

  before(:all) { GrdaWarehouse::Utility.clear! }
  after(:all) { GrdaWarehouse::Utility.clear! }

  let!(:config) { create(:config) }
  let!(:data_source) { create(:source_data_source) }
  let!(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let!(:so_path_project) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      OrganizationID: organization.OrganizationID,
      ProjectType: 4,
    )
  end
  let!(:so_path_funder) do
    create(
      :hud_funder,
      data_source_id: data_source.id,
      ProjectID: so_path_project.ProjectID,
      Funder: 21,
    )
  end
  let!(:so_project_without_path_funder) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      OrganizationID: organization.OrganizationID,
      ProjectType: 4,
    )
  end
  let!(:es_path_funded_project) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      OrganizationID: organization.OrganizationID,
      ProjectType: 1,
    )
  end
  let!(:es_funder) do
    create(
      :hud_funder,
      data_source_id: data_source.id,
      ProjectID: es_path_funded_project.ProjectID,
      Funder: 21,
    )
  end

  def picker_query
    get new_hud_reports_path_path
    expect(response).to have_http_status(:ok)
    select = Nokogiri::HTML(response.body).at_css('select[name="filter[project_ids][]"]')
    expect(select).to be_present
    Rack::Utils.parse_nested_query(select['data-collection-path'].split('?', 2).last)
  end

  shared_examples 'PATH picker wiring' do
    it 'scopes the picker to the permission the report scope uses' do
      expect(picker_query['permission']).to eq('can_view_assigned_reports')
    end

    it 'restricts the picker to PATH project types and the PATH funder' do
      query = picker_query
      expect(query['project_types']).to eq(['so', 'services_only'])
      expect(query['funder_codes']).to eq(['21'])
    end

    it 'returns exactly the PATH-eligible viewable projects when the embedded query is posted back' do
      # Reproduces what stimulus_select_controller.js does with data-collection-path.
      post api_projects_path(format: :json), params: picker_query
      ids = JSON.parse(response.body)['results'].flat_map { |group| group['children'] }.map { |child| child['id'] }
      expect(ids).to contain_exactly(so_path_project.id)
    end
  end

  context 'with an ACL user whose role has can_view_assigned_reports but not can_view_projects' do
    let(:user) { create(:acl_user) }
    let(:role) { create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true) }
    let(:collection) { create(:collection) }

    before do
      collection.set_viewables(projects: [so_path_project.id, so_project_without_path_funder.id, es_path_funded_project.id])
      setup_access_control(user, role, collection)
      sign_in(user)
    end

    include_examples 'PATH picker wiring'
  end

  context 'with a legacy role-based user' do
    let(:user) { create(:user) }
    let(:role) { create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true) }

    before do
      user.legacy_roles << role
      user.add_viewable(data_source)
      sign_in(user)
    end

    include_examples 'PATH picker wiring'

    it 'still returns the PATH-eligible projects once the role loses can_view_assigned_reports, proving the embedded permission is ignored for legacy users' do
      role.update!(can_view_assigned_reports: false)
      query = picker_query
      expect(query['permission']).to eq('can_view_assigned_reports')

      post api_projects_path(format: :json), params: query
      ids = JSON.parse(response.body)['results'].flat_map { |group| group['children'] }.map { |child| child['id'] }
      expect(ids).to contain_exactly(so_path_project.id)
    end
  end
end
