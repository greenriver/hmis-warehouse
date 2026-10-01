###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Expects `user`, `report`, `export`, and `definition_url` (the report definition
# url the export belongs to, e.g. 'hud_reports/aprs') from the including spec.
RSpec.shared_examples 'a hud cell detail export' do
  describe '#authorized?' do
    let(:other_user) { create(:user) }
    let(:definition) do
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      GrdaWarehouse::WarehouseReports::ReportDefinition.find_by!(url: definition_url)
    end

    let(:sibling_definition) do
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      GrdaWarehouse::WarehouseReports::ReportDefinition.hud.where.not(url: definition_url).order(:url).first!
    end

    def grant(role_attrs, granted_definition = definition)
      user.legacy_roles << create(:role, can_view_assigned_reports: true, **role_attrs)
      user.add_viewable(granted_definition)
    end

    it 'is authorized if the user owns the report' do
      grant({})
      report.update!(user_id: user.id)
      expect(export.authorized?).to be true
    end

    it 'is authorized for another user\'s report with can_view_all_hud_reports' do
      grant(can_view_all_hud_reports: true)
      report.update!(user_id: other_user.id)
      expect(export.authorized?).to be true
    end

    it 'is not authorized for another user\'s report without can_view_all_hud_reports' do
      grant({})
      report.update!(user_id: other_user.id)
      expect(export.authorized?).to be false
    end

    it 'is not authorized when the report definition has not been granted' do
      user.legacy_roles << create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true)
      report.update!(user_id: user.id)
      expect(export.authorized?).to be false
    end

    # The gate names this export's own definition url, so holding a different HUD
    # report is not enough.
    it 'is not authorized when only a different HUD report definition has been granted' do
      grant({ can_view_all_hud_reports: true }, sibling_definition)
      report.update!(user_id: user.id)
      expect(export.authorized?).to be false
    end
  end

  describe '#download_title' do
    it 'includes the drilldown name and "Cell Detail"' do
      expect(export.download_title).to include('Cell Detail')
      # The drilldown name comes from the builder, so we verify it's present
      expect(export.download_title).to include(export.send(:builder).drilldown.name)
    end
  end

  describe '#perform' do
    let(:result) { double('Result', filename: 'test.xlsx', data: 'binary-data') }

    it 'calls the builder and updates status' do
      # We mock the builder to avoid deep integration tests here,
      # as we want to test the orchestration in the base class.
      allow(export.send(:builder)).to receive(:call).and_return(result)

      export.perform

      expect(export.filename).to eq('test.xlsx')
      expect(export.file_data).to eq('binary-data')
      expect(export.mime_type).to eq(DocumentExportBehavior::EXCEL_MIME_TYPE)
      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
    end
  end
end
