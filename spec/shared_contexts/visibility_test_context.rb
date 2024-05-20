RSpec.shared_context 'visibility test context', shared_context: :metadata do
  # data
  let!(:warehouse_data_source) { create :grda_warehouse_data_source, source_type: nil }

  let!(:window_visible_data_source) { create :visible_data_source }
  let!(:window_organization) { create :grda_warehouse_hud_organization, data_source_id: window_visible_data_source.id, OrganizationName: 'Visible Org' }
  let!(:window_project) { create :grda_warehouse_hud_project, data_source_id: window_visible_data_source.id, ProjectName: 'Visible Project' }
  let!(:window_project_coc) { create :grda_warehouse_hud_project_coc, data_source_id: window_visible_data_source.id, ProjectID: window_project.ProjectID, CoCCode: 'AA-000' }
  let!(:window_source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source_id: window_visible_data_source.id,
      DOB: 50.years.ago,
      SSN: nil,
    )
  end
  let!(:window_enrollment) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source_id: window_visible_data_source.id,
      PersonalID: window_source_client.PersonalID,
      ProjectID: window_project.ProjectID,
      EntryDate: 1.months.ago.to_date,
    )
  end
  let!(:window_service_history_enrollment) do
    create(
      :grda_warehouse_service_history,
      :service_history_entry,
      project_id: window_project.ProjectID,
      client_id: window_source_client.id,
      enrollment_group_id: window_enrollment.EnrollmentID,
      first_date_in_program: window_enrollment.EntryDate,
      data_source_id: window_visible_data_source.id,
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
  let!(:non_window_organization) { create :grda_warehouse_hud_organization, data_source_id: non_window_visible_data_source.id, OrganizationName: 'Non-Window  Org' }
  let!(:non_window_project) { create :grda_warehouse_hud_project, data_source_id: non_window_visible_data_source.id, ProjectName: 'Non-Window Project' }
  let!(:non_window_project_coc) { create :grda_warehouse_hud_project_coc, data_source_id: non_window_visible_data_source.id, ProjectID: non_window_project.ProjectID, CoCCode: 'ZZ-000' }
  let!(:non_window_source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source_id: non_window_visible_data_source.id,
      DOB: 51.years.ago,
      SSN: nil,
      LastName: 'Moss',
    )
  end
  let!(:non_window_enrollment) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source_id: non_window_visible_data_source.id,
      PersonalID: non_window_source_client.PersonalID,
      ProjectID: non_window_project.ProjectID,
      EntryDate: 1.months.ago.to_date,
    )
  end
  let!(:non_window_service_history_enrollment) do
    create(
      :grda_warehouse_service_history,
      :service_history_entry,
      project_id: non_window_project.ProjectID,
      client_id: non_window_source_client.id,
      enrollment_group_id: non_window_enrollment.EnrollmentID,
      first_date_in_program: non_window_enrollment.EntryDate,
      data_source_id: non_window_visible_data_source.id,
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

  # Client with both non-window and window source data
  let!(:non_window_source_client_2) do
    create(
      :grda_warehouse_hud_client,
      data_source_id: non_window_visible_data_source.id,
      DOB: 51.years.ago,
      SSN: nil,
      FirstName: 'Michele',
    )
  end
  let!(:non_window_enrollment_2) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source_id: non_window_visible_data_source.id,
      PersonalID: non_window_source_client_2.PersonalID,
      ProjectID: non_window_project.ProjectID,
      EntryDate: 1.months.ago.to_date,
    )
  end
  let!(:non_window_service_history_enrollment_2) do
    create(
      :grda_warehouse_service_history,
      :service_history_entry,
      project_id: non_window_project.ProjectID,
      client_id: non_window_source_client_2.id,
      enrollment_group_id: non_window_enrollment_2.EnrollmentID,
      first_date_in_program: non_window_enrollment_2.EntryDate,
      data_source_id: non_window_visible_data_source.id,
    )
  end
  let(:both_destination_client) { create :grda_warehouse_hud_client, data_source_id: warehouse_data_source.id }
  let!(:non_window_warehouse_client_2) do
    create(
      :warehouse_client,
      data_source_id: non_window_visible_data_source.id,
      id_in_source: non_window_source_client_2.PersonalID,
      source_id: non_window_source_client_2.id,
      destination_id: both_destination_client.id,
    )
  end

  let!(:window_source_client_2) do
    create(
      :grda_warehouse_hud_client,
      data_source_id: window_visible_data_source.id,
      DOB: 50.years.ago,
      SSN: nil,
      LastName: 'Foss',
    )
  end
  let!(:window_enrollment_2) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source_id: window_visible_data_source.id,
      PersonalID: window_source_client_2.PersonalID,
      ProjectID: window_project.ProjectID,
      EntryDate: 1.months.ago.to_date,
    )
  end
  let!(:window_service_history_enrollment_2) do
    create(
      :grda_warehouse_service_history,
      :service_history_entry,
      project_id: window_project.ProjectID,
      client_id: window_source_client_2.id,
      enrollment_group_id: window_enrollment_2.EnrollmentID,
      first_date_in_program: window_enrollment_2.EntryDate,
      data_source_id: window_visible_data_source.id,
    )
  end
  let!(:window_warehouse_client_2) do
    create(
      :warehouse_client,
      data_source_id: window_visible_data_source.id,
      id_in_source: window_source_client_2.PersonalID,
      source_id: window_source_client_2.id,
      destination_id: both_destination_client.id,
    )
  end

  # roles
  let!(:can_view_clients) { create :role, can_view_clients: true, can_view_client_name: true }
  let!(:can_create_clients) { create :role, can_create_clients: true }
  let!(:can_search_window) { create :role, can_search_window: true } # START_ACL remove after ACL migration
  let!(:can_use_strict_search) { create :role, can_use_strict_search: true }
  let!(:can_use_separated_consent) { create :role, can_use_separated_consent: true }
  let!(:can_view_all_reports) { create :role, can_view_all_reports: true, can_view_assigned_reports: true }
  let!(:can_edit_users) { create :role, can_edit_users: true }
  let!(:can_manage_config) { create :role, can_manage_config: true }
  let!(:can_edit_data_sources) { create :role, can_edit_data_sources: true, can_view_projects: true }
  let!(:can_search_own_clients) { create :role, can_search_own_clients: true, can_view_client_name: true  }
  let!(:can_search_clients_with_roi) { create :role, can_search_clients_with_roi: true }
  let!(:can_view_client_enrollments_with_roi) { create :role, can_view_client_enrollments_with_roi: true }
  let!(:can_edit_clients) { create :can_edit_clients }
  let!(:no_permission_role) { create :role }

  # Collections
  let!(:no_data_source_access_collection) { create :collection }
  let!(:window_data_source_viewable_collection) { create :collection }
  let!(:window_organization_viewable_collection) { create :collection }
  let!(:window_project_viewable_collection) { create :collection }
  let!(:window_coc_code_viewable_collection) { create :collection, coc_codes: ['AA-000'] }
  let!(:coc_code_viewable_collection) { create :collection }
  before(:each) do
    window_data_source_viewable.add_viewable(window_visible_data_source)
    window_organization_viewable.add_viewable(window_organization)
    window_project_viewable.add_viewable(window_project)
  end

  let!(:non_window_data_source_viewable_collection) { create :collection }
  let!(:non_window_organization_viewable_collection) { create :collection }
  let!(:non_window_project_viewable_collection) { create :collection }
  let!(:non_window_coc_code_viewable_collection) { create :collection, coc_codes: ['ZZ-000'] }
  before(:each) do
    non_window_data_source_viewable_collection.add_viewable(non_window_visible_data_source)
    non_window_organization_viewable_collection.add_viewable(non_window_organization)
    non_window_project_viewable_collection.add_viewable(non_window_project)
  end

  # START_ACL remove after ACL migration
  # groups
  let!(:no_data_source_access_group) { create :access_group }
  let!(:window_data_source_viewable) { create :access_group }
  let!(:window_organization_viewable) { create :access_group }
  let!(:window_project_viewable) { create :access_group }
  let!(:window_coc_code_viewable) { create :access_group, coc_codes: ['AA-000'] }
  let!(:coc_code_viewable) { create :access_group }
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
  # END_ACL
end

RSpec.configure do |rspec|
  rspec.include_context 'visibility test context', include_shared: true
end
