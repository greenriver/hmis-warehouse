###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Youth::Export, type: :model do
  describe '#rows_for_export' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
    let!(:collection) { create(:collection) }

    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
    let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID) }

    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client', DOB: 20.years.ago.to_date) }
    let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
    let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client', DOB: 20.years.ago.to_date) }

    # `DestinationClientPolicy` delegates name visibility to the source client's project-based
    # permissions -- give each source client a real enrollment in the same project the filter
    # restricts `client_scope` to, so an otherwise-visible client's name resolves to visible.
    let!(:restricted_source_enrollment) { create(:hud_enrollment, PersonalID: restricted_source_client.PersonalID, ProjectID: project.ProjectID, data_source: hmis_ds, EntryDate: entry_date) }
    let!(:open_source_enrollment) { create(:hud_enrollment, PersonalID: open_source_client.PersonalID, ProjectID: project.ProjectID, data_source: hmis_ds, EntryDate: entry_date) }

    let(:entry_date) { 6.months.ago.to_date }

    # `client_scope` joins to `clients_within_projects` whenever `filter.all_projects?` is false,
    # so each destination client needs a `ServiceHistoryEnrollment` open in `project` during the
    # filter's date range, independent of whether `all_projects?` resolves true or false.
    let!(:restricted_she) { create(:she_entry, client: restricted_destination_client, project: project, enrollment: restricted_source_enrollment, data_source_id: hmis_ds.id, project_type: project.ProjectType, first_date_in_program: entry_date, last_date_in_program: nil) }
    let!(:open_she) { create(:she_entry, client: open_destination_client, project: project, enrollment: open_source_enrollment, data_source_id: hmis_ds.id, project_type: project.ProjectType, first_date_in_program: entry_date, last_date_in_program: nil) }

    let(:export_options) do
      {
        user_id: running_user.id,
        start: 1.year.ago.to_date,
        end: Date.current,
        project_ids: [project.id],
      }
    end
    let(:export) { described_class.create!(user_id: running_user.id, options: export_options) }

    before do
      # Some ACL/report-scoping lookups (e.g. `Project.viewable_by`) are cached in `Rails.cache`,
      # which lives outside each example's DB transaction rollback -- a value cached while another
      # spec file's now-rolled-back fixtures were live can otherwise leak in here (or vice versa),
      # matching the pattern in `export_covid_impact_assessments_controller_spec.rb`.
      Rails.cache.clear
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

      rows = export.rows_for_export
      restricted_row = row_by_header(export.headers_for_report, rows, key: restricted_destination_client.id)
      open_row = row_by_header(export.headers_for_report, rows, key: open_destination_client.id)

      expect(restricted_row.values_at('First Name', 'Last Name')).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row.values_at('First Name', 'Last Name')).to eq(['Open', 'Client'])
    end

    it 'omits the name columns entirely when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = export.rows_for_export
      restricted_row = row_by_header(export.headers_for_report, rows, key: restricted_destination_client.id)

      expect(restricted_row.keys).not_to include('First Name', 'Last Name')
    end
  end
end
