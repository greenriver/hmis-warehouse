###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Exports::AdHoc, type: :model do
  describe '#rows_for_export' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
    let!(:collection) { create(:collection) }

    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:project) { create(:hud_project, data_source: hmis_ds, ProjectType: 1) } # ES

    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client', DOB: 20.years.ago.to_date) }
    let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
    let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client', DOB: 20.years.ago.to_date) }

    # `DestinationClientPolicy` delegates name visibility to the source client's project-based
    # permissions -- give each source client a real enrollment in a project the collection can
    # view so an otherwise-visible client's name resolves to visible.
    let!(:restricted_source_enrollment) { create(:hud_enrollment, PersonalID: restricted_source_client.PersonalID, ProjectID: project.ProjectID, data_source: hmis_ds) }
    let!(:open_source_enrollment) { create(:hud_enrollment, PersonalID: open_source_client.PersonalID, ProjectID: project.ProjectID, data_source: hmis_ds) }

    # `client_scope` requires an open, head-of-household, homeless (ES/SO/SH/TH) enrollment for
    # each client -- `clients_with_ongoing_enrollments`, `heads_of_household`, and
    # `filter_for_sub_population` (default sub-population `:clients` still merges `.homeless`).
    def build_open_enrollment(client)
      create(:she_entry, client: client, project_type: 1, head_of_household: true, first_date_in_program: 1.month.ago.to_date, last_date_in_program: nil)
    end
    let!(:restricted_she) { build_open_enrollment(restricted_destination_client) }
    let!(:open_she) { build_open_enrollment(open_destination_client) }

    let(:ad_hoc_options) do
      {
        user_id: running_user.id,
        start: 1.year.ago.to_date,
        end: Date.current,
      }
    end
    let(:ad_hoc) { described_class.create!(user_id: running_user.id, options: ad_hoc_options) }

    before do
      # Some ACL/report-scoping lookups (e.g. `Project.viewable_by`) are cached in `Rails.cache`,
      # which lives outside each example's DB transaction rollback -- a value cached while another
      # spec file's now-rolled-back fixtures were live can otherwise leak in here (or vice versa;
      # see `youth/export_spec.rb`).
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

      rows = ad_hoc.rows_for_export
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      open_row = rows.find { |r| r[0] == open_destination_client.id }

      expect(restricted_row[1..2]).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row[1..2]).to eq(['Open', 'Client'])
    end

    # `headers_for_report` has no `include_pii_in_detail_downloads` gate at all -- name columns
    # are always present -- so `reporting_policy_for_client`'s own toggle check is what redacts
    # every client's name when the toggle is off, not row/column omission.
    it 'redacts every client name when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = ad_hoc.rows_for_export
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      open_row = rows.find { |r| r[0] == open_destination_client.id }

      expect(restricted_row[1..2]).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row[1..2]).to eq(['Name Redacted', 'Name Redacted'])
    end
  end
end
