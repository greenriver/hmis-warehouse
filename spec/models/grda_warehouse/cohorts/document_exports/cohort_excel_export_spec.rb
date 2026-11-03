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
  end
end
