FactoryBot.define do
  factory :role, class: 'Role' do
    name { 'role' }
  end

  factory :admin_role, class: 'Role' do
    name { 'admin' }
    verb { nil }
    can_view_clients { true }
    can_edit_clients { true }
    can_view_all_reports { true }
    can_view_assigned_reports { true }
    can_assign_reports { true }
    can_view_census_details { true }
    can_edit_users { true }
    can_view_full_ssn { true }
    can_view_full_dob { true }
    can_view_hiv_status { true }
    can_view_dmh_status { true }
    can_view_imports { true }
    can_edit_roles { true }
    can_view_projects { true }
    can_edit_projects { true }
    can_edit_project_groups { true }
    can_view_organizations { true }
    can_edit_organizations { true }
    can_edit_data_sources { true }
    can_view_client_window { true }
    can_upload_hud_zips { true }
    can_edit_translations { true }
    can_manage_assessments { true }
    can_administer_health { true }
    can_edit_client_health { true }
    can_view_client_health { true }
    health_role { false }
    can_manage_config { true }
    can_manage_client_files { true }
    can_manage_window_client_files { true }
    can_edit_dq_grades { true }
    can_view_vspdat { true }
    can_edit_vspdat { true }
    can_edit_client_notes { true }
    can_edit_window_client_notes { true }
    can_track_anomalies { true }
    can_add_administrative_event { true }
  end

  factory :health_admin, class: 'Role' do
    name { 'health admin' }
    verb { nil }
    health_role { true }
    can_view_assigned_reports { true }
    can_administer_health { true }
    can_edit_client_health { true }
    can_view_client_health { true }
  end

  factory :vispdat_viewer, class: 'Role' do
    name { 'vispdat viewer' }
    can_view_vspdat { true }
    can_search_window { true }
  end

  factory :vispdat_editor, class: 'Role' do
    name { 'vispdat editor' }
    can_view_vspdat { true }
    can_edit_vspdat { true }
    can_search_window { true }
  end

  factory :cohort_manager, class: 'Role' do
    name { 'cohort manager' }
    can_manage_cohorts { true }
  end

  factory :cohort_client_editor, class: 'Role' do
    name { 'cohort client editor' }
    can_edit_assigned_cohorts { true }
  end

  factory :cohort_client_viewer, class: 'Role' do
    name { 'cohort client viewer' }
    can_view_assigned_cohorts { true }
  end

  factory :report_viewer, class: 'Role' do
    name { 'cohort client viewer' }
    can_view_all_reports { true }
  end

  factory :assigned_report_viewer, class: 'Role' do
    name { 'cohort client viewer' }
    can_view_assigned_reports { true }
  end

  factory :assigned_ds_viewer, class: 'Role' do
    name { 'ds viewer' }
    can_see_clients_in_window_for_assigned_data_sources { true }
  end

  factory :secure_file_recipient, class: 'Role' do
    name { 'secure file recipient' }
    can_view_assigned_secure_uploads { true }
  end

  factory :secure_file_admin, class: 'Role' do
    name { 'secure file admin' }
    can_view_all_secure_uploads { true }
  end

  factory :can_view_all_hud_reports, class: 'Role' do
    name { 'can view all hud reports' }
    can_view_all_hud_reports { true }
  end

  factory :can_view_youth_intake, class: 'Role' do
    name { 'can view youth intake' }
    can_view_youth_intake { true }
    can_search_window { true }
  end

  factory :can_view_own_agency_youth_intake, class: 'Role' do
    name { 'can view own agency youth intake' }
    can_view_own_agency_youth_intake { true }
    can_search_window { true }
  end

  factory :can_edit_own_agency_youth_intake, class: 'Role' do
    name { 'can edit own agency youth intake' }
    can_edit_own_agency_youth_intake { true }
    can_search_window { true }
  end

  factory :can_create_clients, class: 'Role' do
    name { 'can create clients' }
    can_create_clients { true }
    can_search_window { true }
  end

  factory :can_search_window, class: 'Role' do
    name { 'can search window' }
    can_search_window { true }
  end

  factory :can_view_client_window, class: 'Role' do
    name { 'can view clients' }
    can_view_client_window { true }
  end

  factory :can_edit_clients, class: 'Role' do
    name { 'can view clients' }
    can_edit_clients { true }
  end
end
