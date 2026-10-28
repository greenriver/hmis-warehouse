###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'inactive client report fixtures' do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_clients: true, can_view_client_name: true, can_view_full_dob: true) }
  let!(:report_definition) { create(:touch_point_report, url: InactiveClientReport::Report.url, name: 'Client Activity Report') }

  let!(:destination_ds) { create(:destination_data_source) }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

  # `Report#report_scope` keeps only enrollments ongoing on `filter.on`.
  let(:on_date) { Date.current }
  let(:entry_date) { 6.months.ago.to_date }

  before do
    # Some ACL/report-scoping lookups (e.g. `Project.viewable_by`) are cached in `Rails.cache`,
    # which lives outside each example's DB transaction rollback -- a value cached while another
    # spec file's now-rolled-back fixtures were live can otherwise leak in here.
    Rails.cache.clear
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
  end

  # Builds a destination client with one source client enrolled (open, no exit) in `project`,
  # plus the matching service history entry the report reads.
  def create_report_client(first_name:, last_name:, data_source: hmis_ds, enrollment_project: project, dob: '1990-06-15', personal_id: nil)
    destination = create(:grda_warehouse_hud_client, data_source: destination_ds, FirstName: first_name, LastName: last_name, DOB: dob)
    source_attrs = { data_source: data_source, FirstName: first_name, LastName: last_name, DOB: dob }
    source_attrs[:PersonalID] = personal_id if personal_id
    source = create(:grda_warehouse_hud_client, **source_attrs)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: data_source.id, id_in_source: source.PersonalID)
    enrollment = create(:hud_enrollment, data_source: data_source, PersonalID: source.PersonalID, ProjectID: enrollment_project.ProjectID, EntryDate: entry_date)
    create(
      :she_entry,
      client: destination,
      data_source_id: data_source.id,
      project_id: enrollment_project.ProjectID,
      organization_id: enrollment_project.OrganizationID,
      enrollment_group_id: enrollment.EnrollmentID,
      project_type: enrollment_project.ProjectType,
      first_date_in_program: entry_date,
      last_date_in_program: nil,
    )
    destination
  end

  def source_enrollment_for(destination)
    GrdaWarehouse::Hud::Enrollment.find_by!(PersonalID: destination.source_clients.first.PersonalID, data_source_id: destination.source_clients.first.data_source_id)
  end

  # Creates a HUD record (service, CLS, assessment) on the destination client's source enrollment.
  def create_enrollment_record(factory, destination, **attributes)
    enrollment = source_enrollment_for(destination)
    create(factory, data_source_id: enrollment.data_source_id, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID, **attributes)
  end

  def report_filter(**overrides)
    Filters::FilterBase.new(user_id: user.id).set_from_params(
      {
        on: on_date,
        start: 1.year.ago.to_date,
        end: on_date,
        project_ids: [project.id],
        require_service_during_range: false,
      }.merge(overrides).with_indifferent_access,
    )
  end
end
