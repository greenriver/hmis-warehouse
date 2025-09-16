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
    context 'when user can download cohorts' do
      it 'returns true' do
        export = GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.new(user_id: user.id)
        expect(export.authorized?).to be true
      end
    end

    context 'when user cannot download cohorts' do
      it 'returns false' do
        role.update(can_download_cohorts: false)
        export = GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.new(user_id: user.id)
        expect(export.authorized?).to be false
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
  end
end
