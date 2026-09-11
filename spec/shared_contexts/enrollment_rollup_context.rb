###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'enrollment rollup context' do
  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  let!(:config) { create :config, expose_coc_code: false, ineligible_uses_extrapolated_days: false, so_day_as_month: false }
  let!(:warehouse_data_source) { create :grda_warehouse_data_source, source_type: nil }
  let!(:data_source) { create :visible_data_source }
  let!(:export) { create :hud_export, data_source_id: data_source.id }
  let!(:organization) { create :hud_organization, data_source_id: data_source.id, OrganizationName: 'Test Org' }

  let!(:shelter_a) { create_project('Shelter A', project_type: 0) }
  let!(:shelter_b) { create_project('Shelter B', project_type: 0) }
  let!(:housing) { create_project('Housing', project_type: 3) }

  let!(:destination_client) { create :hud_client, data_source_id: warehouse_data_source.id, FirstName: 'Dest', LastName: 'Client' }
  let!(:source_client) { create_linked_source_client(destination_client, first_name: 'Sam', last_name: 'Source') }

  let!(:household_member_destination) { create :hud_client, data_source_id: warehouse_data_source.id, FirstName: 'Mia', LastName: 'Member' }
  let!(:household_member_source) { create_linked_source_client(household_member_destination, first_name: 'Mia', last_name: 'Member', dob: '1990-01-01') }

  let!(:shelter_a_enrollment) do
    create_enrollment(source_client, shelter_a, entry: '2021-01-01', exit_date: '2021-01-11', HouseholdID: 'hh-a', RelationshipToHoH: 1)
  end
  let!(:household_member_enrollment) do
    create_enrollment(household_member_source, shelter_a, entry: '2021-01-01', exit_date: '2021-01-11', HouseholdID: 'hh-a', RelationshipToHoH: 2)
  end
  let!(:shelter_b_enrollment) do
    create_enrollment(source_client, shelter_b, entry: '2021-01-06', exit_date: '2021-01-20')
  end
  let!(:housing_enrollment) do
    create_enrollment(source_client, housing, entry: '2021-01-15', exit_date: '2021-02-01', MoveInDate: '2021-01-18')
  end

  let!(:user) { create :acl_user }
  let!(:viewer_role) do
    create(
      :role,
      can_view_clients: true,
      can_view_client_name: true,
      can_view_limited_client_dashboard: true,
      can_view_projects: true,
      can_view_enrollment_details: true,
    )
  end
  # Source-data visibility needs an editable source data source; keep it to the one
  # fixture data source so the hidden-enrollment example stays hidden.
  let!(:source_editor_role) { create :role, can_upload_hud_zips: true, can_edit_data_sources: true }
  let!(:source_editor_collection) do
    collection = create :collection, name: 'Rollup fixture data source'
    collection.set_viewables({ data_sources: [data_source.id] })
    collection
  end

  before do
    # Data sources are created above via let!, after the outer before block's
    # Collection.maintain_system_groups ran, so window_data_sources doesn't yet
    # know about them; refresh it before granting access through it.
    Collection.maintain_system_groups
    setup_access_control(user, viewer_role, Collection.system_collection(:window_data_sources))
    setup_access_control(user, source_editor_role, source_editor_collection)
    rebuild_service_history!
  end

  def create_project(name, project_type:, **attrs)
    create(
      :hud_project,
      data_source_id: data_source.id,
      OrganizationID: organization.OrganizationID,
      ProjectName: name,
      ProjectType: project_type,
      ExportID: export.ExportID,
      **attrs,
    )
  end

  # An ACL user holding only `role` over the window data sources; contrast with `user`,
  # who also has source-data editing access.
  def create_user_with_role(role)
    acl_user = create :acl_user
    setup_access_control(acl_user, role, Collection.system_collection(:window_data_sources))
    acl_user
  end

  def create_linked_source_client(destination, first_name:, last_name:, dob: '1980-01-01')
    source = create(:hud_client, data_source_id: data_source.id, FirstName: first_name, LastName: last_name, DOB: dob)
    create(:warehouse_client, destination_id: destination.id, source_id: source.id, data_source_id: data_source.id, id_in_source: source.PersonalID)
    source
  end

  def create_enrollment(client, project, entry:, exit_date:, **attrs)
    enrollment = create(
      :hud_enrollment,
      data_source_id: data_source.id,
      PersonalID: client.PersonalID,
      ProjectID: project.ProjectID,
      EntryDate: Date.parse(entry),
      ExportID: export.ExportID,
      **{ DisablingCondition: 0 }.merge(attrs),
    )
    create(
      :hud_exit,
      data_source_id: data_source.id,
      PersonalID: client.PersonalID,
      EnrollmentID: enrollment.EnrollmentID,
      ExitDate: Date.parse(exit_date),
      Destination: 10,
    )
    enrollment
  end

  # Builds a second destination client whose enrollments all look like Shelter A
  # (ES-EE, exited, one household member each) so query counts can be compared
  # across enrollment counts. With shared_household_member: true, every enrollment's
  # household lists the SAME member client (across separate HouseholdIDs) instead of
  # a distinct one, so the page displays that one person `count` times.
  def build_client_with_es_enrollments(count:, shared_household_member: false)
    destination = create :hud_client, data_source_id: warehouse_data_source.id, FirstName: 'Many', LastName: "Client#{count}"
    source = create_linked_source_client(destination, first_name: 'Many', last_name: "Source#{count}")
    if shared_household_member
      shared_member_source = create_linked_source_client(
        create(:hud_client, data_source_id: warehouse_data_source.id, FirstName: 'Shared', LastName: 'Member'),
        first_name: 'Shared',
        last_name: 'Member',
      )
    end
    count.times do |i|
      entry = Date.new(2020, 1, 1) + (i * 20).days
      hh_id = "hh-#{count}-#{i}"
      create_enrollment(source, shelter_a, entry: entry.to_s, exit_date: (entry + 10.days).to_s, HouseholdID: hh_id, RelationshipToHoH: 1)
      member_source = if shared_household_member
        shared_member_source
      else
        member_destination = create :hud_client, data_source_id: warehouse_data_source.id, FirstName: "Member#{i}", LastName: 'Many'
        create_linked_source_client(member_destination, first_name: "Member#{i}", last_name: 'Many')
      end
      create_enrollment(member_source, shelter_a, entry: entry.to_s, exit_date: (entry + 10.days).to_s, HouseholdID: hh_id, RelationshipToHoH: 2)
    end
    rebuild_service_history!
    destination
  end

  def rebuild_service_history!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
  end
end
