###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::TimeHomelessForExit, type: :model do
  describe '#rows_for_export' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) do
      create(
        :role,
        can_view_project_related_filters: true,
        can_view_assigned_reports: true,
        can_view_projects: true,
        can_view_client_name: true,
        can_view_clients: true,
      )
    end
    let!(:collection) { create(:collection) }

    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
    let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
    let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
    let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }

    let(:destination_code) { HudHelper.util.permanent_destinations.first }
    let(:entry_date) { 6.months.ago.to_date }
    let(:exit_date) { 1.month.ago.to_date }

    # `clients_with_permanent_exits` walks a real `GrdaWarehouse::Hud::Enrollment` joined to its
    # `Hud::Exit`; `homeless_entries` separately walks the destination client's
    # `ServiceHistoryEnrollment`, which must point back at that same `Enrollment` for
    # `client_homeless_entry_dates` to resolve a project name for the row.
    def build_exit_with_entry(source_client:, destination_client:)
      enrollment = create(:hud_enrollment, PersonalID: source_client.PersonalID, ProjectID: project.ProjectID, data_source: hmis_ds, EntryDate: entry_date)
      create(:hud_exit, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID, data_source: hmis_ds, ExitDate: exit_date, Destination: destination_code)
      she = create(:she_entry, client: destination_client, project: project, enrollment: enrollment, record_type: :entry, project_type: 1, first_date_in_program: entry_date, last_date_in_program: nil)
      create(:service_history_service, service_history_enrollment: she, client: destination_client, date: entry_date, record_type: 'service')
      she
    end
    let!(:restricted_enrollment) { build_exit_with_entry(source_client: restricted_source_client, destination_client: restricted_destination_client) }
    let!(:open_enrollment) { build_exit_with_entry(source_client: open_source_client, destination_client: open_destination_client) }

    let(:filter) { ::Filters::FilterBase.new(user_id: running_user.id, start: 1.year.ago.to_date, end: Date.current) }
    let(:report) { described_class.new(filter) }

    before do
      Collection.maintain_system_groups
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(running_user, role, collection)
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    after { GrdaWarehouse::Config.invalidate_cache }

    it 'redacts the restricted client and shows the real name for the unrestricted client when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      rows = report.rows_for_export
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      open_row = rows.find { |r| r[0] == open_destination_client.id }

      expect(restricted_row[1..2]).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row[1..2]).to eq(['Open', 'Client'])
    end

    it 'omits the name columns entirely when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = report.rows_for_export
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }

      expect(restricted_row.size).to eq(6)
    end
  end
end
