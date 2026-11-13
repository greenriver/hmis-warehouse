###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport, type: :model do
  let(:user) { create(:acl_user) }
  let(:data_source) { create(:source_data_source, visible_in_window: true) }
  let(:cohort) { create(:cohort) }
  let(:client) { create(:grda_warehouse_hud_client, data_source: data_source) }
  let!(:cohort_client) { create(:cohort_client, cohort: cohort, client: client) }
  let!(:role) { create(:role, can_download_cohorts: true, can_view_cohorts: true) }
  let!(:cohort_collection) { create(:collection, collection_type: 'Cohorts') }
  let!(:tabs) do
    GrdaWarehouse::CohortTab.default_rules.each do |rule|
      cohort.cohort_tabs.create(**rule)
    end
  end

  before do
    GrdaWarehouse::Cohorts::CohortColumn.maintain!
    cohort_collection.set_viewables({ cohorts: [cohort.id] })
    setup_access_control(user, role, cohort_collection)
  end

  describe '#authorized?' do
    def export_for(cohort_id)
      described_class.new(user_id: user.id, query_string: { id: cohort_id }.to_query)
    end

    context 'when user can download cohorts' do
      it 'returns true' do
        expect(export_for(cohort.id).authorized?).to be true
      end
    end

    context 'when user cannot download cohorts' do
      it 'returns false' do
        role.update(can_download_cohorts: false)
        expect(export_for(cohort.id).authorized?).to be false
      end
    end

    context 'when the user can download cohorts but cannot view this cohort' do
      let(:other_cohort) { create(:cohort) }

      it 'returns false' do
        expect(export_for(other_cohort.id).authorized?).to be false
      end
    end

    context 'when the cohort is removed from the user\'s collection after the export was built' do
      it 'returns false' do
        expect(export_for(cohort.id).authorized?).to be true

        cohort_collection.set_viewables({ cohorts: [] })
        expect(export_for(cohort.id).authorized?).to be false
      end
    end

    context 'when the request names the cohort with cohort_id, as the cohort report page does' do
      def report_page_export_for(cohort_id)
        described_class.new(user_id: user.id, query_string: { cohort_id: cohort_id }.to_query)
      end

      it 'returns true for a cohort the user can view' do
        expect(report_page_export_for(cohort.id).authorized?).to be true
      end

      it 'returns false for a cohort the user cannot view' do
        expect(report_page_export_for(create(:cohort).id).authorized?).to be false
      end
    end
  end

  describe '#perform' do
    let(:export) do
      GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.new(
        user_id: user.id,
        query_string: "id=#{cohort.id}&population=Active+Clients",
      )
    end

    it 'creates a valid export file' do
      expect { export.perform }.not_to raise_error

      expect(export.status).to eq(GrdaWarehouse::DocumentExport::COMPLETED_STATUS)
      expect(export.file_data).not_to be_nil
      expect(export.mime_type).to eq(GrdaWarehouse::DocumentExport::EXCEL_MIME_TYPE)

      # Use Roo to verify Excel content
      excel_file = Tempfile.new(['cohort_export', '.xlsx'])
      begin
        excel_file.binmode
        excel_file.write(export.file_data)
        excel_file.close

        spreadsheet = Roo::Excelx.new(excel_file.path)
        sheet = spreadsheet.sheet(0)

        # Verify the header row
        first_row = sheet.row(1)
        expect(first_row[0]).to eq('Warehouse Client ID')
        # Verify the client row
        client_row = sheet.row(2)
        expect(client_row[0]).to eq(client.id)
      ensure
        excel_file.unlink
      end
    end

    it 'exports the cohort named by cohort_id' do
      export = described_class.new(user_id: user.id, query_string: { cohort_id: cohort.id, population: 'Active Clients' }.to_query)
      export.perform

      expect(export.status).to eq(GrdaWarehouse::DocumentExport::COMPLETED_STATUS)
      expect(export.filename).to start_with("Cohort - #{cohort.name} - Active Clients - ")
    end

    context 'with more clients than the preload-miss threshold, one of them restricted in HMIS' do
      let(:hmis_ds) { create(:hmis_primary_data_source) }
      let(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
      let(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
      let!(:restricted_client) { create(:grda_warehouse_hud_client, data_source: data_source, FirstName: 'Restricted', LastName: 'Client') }
      let!(:open_clients) do
        (1..GrdaWarehouse::AuthPolicies::PreloadMissTracker::THRESHOLD).map do |i|
          create(:grda_warehouse_hud_client, data_source: data_source, FirstName: "Open#{i}", LastName: 'Client')
        end
      end

      before do
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        ([restricted_client] + open_clients).each { |c| create(:cohort_client, cohort: cohort, client: c) }
      end

      def names_by_client_id(file_data)
        file = Tempfile.new(['cohort_export', '.xlsx'])
        file.binmode
        file.write(file_data)
        file.close
        sheet = Roo::Excelx.new(file.path).sheet(0)
        headers = sheet.row(1)
        id_index = headers.index('Warehouse Client ID')
        first_index = headers.index('First Name')
        last_index = headers.index('Last Name')
        (2..sheet.last_row).to_h do |i|
          row = sheet.row(i)
          [row[id_index], [row[first_index], row[last_index]]]
        end
      ensure
        file&.unlink
      end

      it 'redacts the restricted client and shows names for the others' do
        export.perform

        expect(export.status).to eq(GrdaWarehouse::DocumentExport::COMPLETED_STATUS)
        names = names_by_client_id(export.file_data)
        expect(names[restricted_client.id]).to eq(['Name Redacted', 'Name Redacted'])
        open_clients.each do |c|
          expect(names[c.id]).to eq([c.FirstName, 'Client'])
        end
      end
    end
  end
end
