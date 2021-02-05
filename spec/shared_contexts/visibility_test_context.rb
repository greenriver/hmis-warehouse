RSpec.shared_context 'visibility test context', shared_context: :metadata do
  # data
  let!(:warehouse_data_source) { create :grda_warehouse_data_source }

  let!(:window_visible_data_source) { create :visible_data_source }
  let!(:window_organization) { create :grda_warehouse_hud_organization, data_source_id: window_visible_data_source.id, OrganizationName: 'Visible Org' }
  let!(:window_project) { create :grda_warehouse_hud_project, data_source_id: window_visible_data_source.id, ProjectName: 'Visible Project' }
  let!(:window_project_coc) { create :grda_warehouse_hud_project_coc, data_source_id: window_visible_data_source.id, ProjectID: window_project.ProjectID, CoCCode: 'AA-000' }
  let!(:window_source_client) { create :grda_warehouse_hud_client, data_source_id: window_visible_data_source.id }
  let!(:window_enrollment) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source_id: window_visible_data_source.id,
      PersonalID: window_source_client.PersonalID,
      ProjectID: window_project.ProjectID,
    )
  end
  let(:window_destination_client) { create :grda_warehouse_hud_client, data_source_id: warehouse_data_source.id }
  let!(:window_warehouse_client) do
    create(
      :warehouse_client,
      data_source_id: window_visible_data_source.id,
      id_in_source: window_source_client.PersonalID,
      source_id: window_source_client.id,
      destination_id: window_destination_client.id,
    )
  end

  let!(:non_window_visible_data_source) { create :non_window_data_source }
  let!(:non_window_organization) { create :grda_warehouse_hud_organization, data_source_id: non_window_visible_data_source.id, OrganizationName: 'Visible Org' }
  let!(:non_window_project) { create :grda_warehouse_hud_project, data_source_id: non_window_visible_data_source.id, ProjectName: 'Visible Project' }
  let!(:non_window_project_coc) { create :grda_warehouse_hud_project_coc, data_source_id: non_window_visible_data_source.id, ProjectID: non_window_project.ProjectID, CoCCode: 'ZZ-000' }
  let!(:non_window_source_client) { create :grda_warehouse_hud_client, data_source_id: non_window_visible_data_source.id }
  let!(:non_window_enrollment) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source_id: non_window_visible_data_source.id,
      PersonalID: non_window_source_client.PersonalID,
      ProjectID: non_window_project.ProjectID,
    )
  end
  let(:non_window_destination_client) { create :grda_warehouse_hud_client, data_source_id: warehouse_data_source.id }
  let!(:non_window_warehouse_client) do
    create(
      :warehouse_client,
      data_source_id: non_window_visible_data_source.id,
      id_in_source: non_window_source_client.PersonalID,
      source_id: non_window_source_client.id,
      destination_id: non_window_destination_client.id,
    )
  end

  # roles
  let!(:can_view_clients) { create :role, can_view_clients: true }
  let!(:can_see_clients_in_window_for_assigned_data_sources) { create :role, can_see_clients_in_window_for_assigned_data_sources: true }
  let!(:can_view_clients_with_roi_in_own_coc) { create :role, can_view_clients_with_roi_in_own_coc: true }
  let!(:can_search_window) { create :role, can_search_window: true }
  let!(:can_view_client_window) { create :role, can_view_client_window: true }
  let!(:can_use_separated_consent) { create :role, can_use_separated_consent: true }
  let!(:can_view_all_reports) { create :role, can_view_all_reports: true }
  let!(:can_edit_users) { create :role, can_edit_users: true }
  let!(:can_manage_config) { create :role, can_manage_config: true }
  let!(:can_edit_data_sources) { create :role, can_edit_data_sources: true, can_view_projects: true }

  # groups
  let!(:window_data_source_viewable) { create :access_group }
  let!(:window_organization_viewable) { create :access_group }
  let!(:window_project_viewable) { create :access_group }
  let!(:window_coc_code_viewable) { create :access_group, coc_codes: ['AA-000'] }
  before(:each) do
    window_data_source_viewable.add_viewable(window_visible_data_source)
    window_organization_viewable.add_viewable(window_organization)
    window_project_viewable.add_viewable(window_project)
  end

  let!(:non_window_data_source_viewable) { create :access_group }
  let!(:non_window_organization_viewable) { create :access_group }
  let!(:non_window_project_viewable) { create :access_group }
  let!(:non_window_coc_code_viewable) { create :access_group, coc_codes: ['ZZ-000'] }
  before(:each) do
    non_window_data_source_viewable.add_viewable(non_window_visible_data_source)
    non_window_organization_viewable.add_viewable(non_window_organization)
    non_window_project_viewable.add_viewable(non_window_project)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'visibility test context', include_shared: true
end
