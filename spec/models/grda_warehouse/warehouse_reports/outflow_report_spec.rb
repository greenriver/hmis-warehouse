###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::OutflowReport, type: :model do
  describe '#rows_for_export' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
    let!(:collection) { create(:collection) }

    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:project_data_source) { create(:grda_warehouse_data_source) }
    let!(:organization) { create(:hud_organization, data_source: project_data_source) }
    let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
    let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
    let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }

    # `DestinationClientPolicy` delegates name visibility to the source client's project-based
    # permissions -- give each source client a real enrollment in a project the collection can
    # view so an otherwise-visible client's name actually resolves to visible.
    let!(:permission_project) { create(:hud_project, data_source: hmis_ds) }
    let!(:restricted_source_enrollment) { create(:hud_enrollment, PersonalID: restricted_source_client.PersonalID, ProjectID: permission_project.ProjectID, data_source: hmis_ds) }
    let!(:open_source_enrollment) { create(:hud_enrollment, PersonalID: open_source_client.PersonalID, ProjectID: permission_project.ProjectID, data_source: hmis_ds) }

    let(:destination_code) { HudHelper.util.permanent_destinations.first }

    def build_exit(client)
      create(
        :she_entry,
        client: client,
        project: project,
        project_type: 1,
        first_date_in_program: 6.months.ago.to_date,
        last_date_in_program: 1.month.ago.to_date,
        destination: destination_code,
      )
    end
    let!(:restricted_she) { build_exit(restricted_destination_client) }
    let!(:open_she) { build_exit(open_destination_client) }

    let(:filter) { ::Filters::OutflowReport.new(user_id: running_user.id, start: 1.year.ago.to_date, end: Date.current) }
    let(:report) { described_class.new(filter, running_user) }

    before do
      Collection.maintain_system_groups
      collection.set_viewables({ projects: [project.id, permission_project.id] })
      setup_access_control(running_user, role, collection)
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    after { GrdaWarehouse::Config.invalidate_cache }

    it 'redacts the restricted client and shows the real name for the unrestricted client when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      rows = report.rows_for_export(:clients_to_ph)
      restricted_row = row_by_header(report.headers_for_export, rows, key: restricted_destination_client.id)
      open_row = row_by_header(report.headers_for_export, rows, key: open_destination_client.id)

      expect(restricted_row.values_at('First Name', 'Last Name')).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row.values_at('First Name', 'Last Name')).to eq(['Open', 'Client'])
    end

    it 'omits the name columns entirely when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = report.rows_for_export(:clients_to_ph)
      restricted_row = row_by_header(report.headers_for_export, rows, key: restricted_destination_client.id)

      expect(restricted_row.keys).not_to include('First Name', 'Last Name')
      expect(restricted_row['Project Type']).to eq(HudHelper.util.project_type_brief(1))
    end
  end
end
