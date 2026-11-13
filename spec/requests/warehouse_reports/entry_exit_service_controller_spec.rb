###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::EntryExitServiceController#index', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/entry_exit_service', name: 'Clients with Single Day Enrollments with Services') }

  let!(:source_ds) { create(:source_data_source) }
  let!(:destination_ds) { create(:destination_data_source) }
  let!(:organization) { create(:hud_organization, data_source_id: source_ds.id) }
  let!(:project) { create(:hud_project, data_source_id: source_ds.id, OrganizationID: organization.OrganizationID, ProjectType: 1) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  # `Hmis::RestrictedRecord` is created against this client; restriction then propagates
  # to every source client sharing its destination identity (see `RestrictedClientLoader`).
  let!(:restriction_marker_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:destination_client) { create(:grda_warehouse_hud_client, data_source: destination_ds) }
  # The enrollment/exit/service records below belong to this source client's PersonalID.
  let!(:enrollment_source_client) { create(:grda_warehouse_hud_client, data_source: source_ds, FirstName: 'Restrictedfirst', LastName: 'Restrictedlast') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, data_source: destination_ds) }
  let!(:open_source_client) { create(:grda_warehouse_hud_client, data_source: source_ds, FirstName: 'Openfirst', LastName: 'Openlast') }

  let(:single_day) { Date.current }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)

    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: restriction_marker_client.id, data_source_id: hmis_ds.id, id_in_source: restriction_marker_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: enrollment_source_client.id, data_source_id: source_ds.id, id_in_source: enrollment_source_client.id.to_s)
    restriction_marker_client.mark_as_restricted!(user: hmis_user)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: source_ds.id, id_in_source: open_source_client.id.to_s)

    enrollment = create(:hud_enrollment, data_source_id: source_ds.id, PersonalID: enrollment_source_client.PersonalID, ProjectID: project.ProjectID, EntryDate: single_day)
    create(:hud_exit, data_source_id: source_ds.id, PersonalID: enrollment_source_client.PersonalID, EnrollmentID: enrollment.EnrollmentID, ExitDate: single_day)
    create(:hud_service, data_source_id: source_ds.id, PersonalID: enrollment_source_client.PersonalID, EnrollmentID: enrollment.EnrollmentID, DateProvided: single_day, RecordType: 5)
    open_enrollment = create(:hud_enrollment, data_source_id: source_ds.id, PersonalID: open_source_client.PersonalID, ProjectID: project.ProjectID, EntryDate: single_day)
    create(:hud_exit, data_source_id: source_ds.id, PersonalID: open_source_client.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, ExitDate: single_day)
    create(:hud_service, data_source_id: source_ds.id, PersonalID: open_source_client.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, DateProvided: single_day, RecordType: 5)

    sign_in user
  end

  it 'redacts only the restricted client name in the html view' do
    get warehouse_reports_entry_exit_service_index_path

    expect(response.body).not_to include('Restrictedfirst')
    expect(response.body).not_to include('Restrictedlast')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('Openfirst')
    expect(response.body).to include('Openlast')
  end

  def rendered_workbook
    excel_file = Tempfile.new(['entry_exit_service', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts only the restricted client name in the Excel export' do
    get warehouse_reports_entry_exit_service_index_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
    expect(rows.flatten).not_to include('Restrictedfirst', 'Restrictedlast')
    expect(rows.flatten).to include('Name Redacted')
    expect(rows.flatten).to include('Openfirst', 'Openlast')
  end
end
