###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::DocumentExports::CellDetailExport, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user) }
  let(:export) do
    described_class.new(
      user: user,
      query_string: {
        report_id: report.id,
        measure_id: 'Question 5',
        cell_id: 'B2',
        table: '5a',
        report_type: 'apr'
      }.to_query
    )
  end

  describe '#authorized?' do
    it 'returns true if user has HUD report permissions and owns the report' do
      user.legacy_roles << create(:role, can_view_own_hud_reports: true)
      expect(export.authorized?).to be true
    end

    it 'returns true if user has can_view_all_hud_reports permission' do
      other_user = create(:user)
      other_user.legacy_roles << create(:role, can_view_all_hud_reports: true)
      export.user = other_user
      expect(export.authorized?).to be true
    end

    it 'returns false if user has no HUD permissions' do
      expect(export.authorized?).to be false
    end

    it 'returns false if user owns HUD reports but not this one' do
      user.legacy_roles << create(:role, can_view_own_hud_reports: true)
      other_report = create(:hud_reports_report_instance, user: create(:user))
      export.query_string = { report_id: other_report.id, report_type: 'apr', measure_id: 'Q5', table: '5a', cell_id: 'B2' }.to_query
      expect(export.authorized?).to be false
    end
  end

  describe '#perform' do
    it 'orchestrates the builder execution' do
      builder = instance_double(HudApr::CellDetailExportBuilder)
      result = HudApr::CellDetailExportBuilder::Result.new(
        name: 'Test',
        filename: 'test.xlsx',
        data: 'xlsx-data'
      )

      allow(HudApr::CellDetailExportBuilder).to receive(:new).and_return(builder)
      allow(builder).to receive(:call).and_return(result)

      export.perform

      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
      expect(export.filename).to eq('test.xlsx')
      expect(export.file_data).to eq('xlsx-data')
      expect(export.mime_type).to eq(DocumentExportBehavior::EXCEL_MIME_TYPE)
    end
  end

  describe '#download_title' do
    it 'generates a descriptive title' do
      user.legacy_roles << create(:role, can_view_own_hud_reports: true)
      expect(export.download_title).to match(/Question 5/)
      expect(export.download_title).to match(/Cell Detail/)
    end
  end
end
