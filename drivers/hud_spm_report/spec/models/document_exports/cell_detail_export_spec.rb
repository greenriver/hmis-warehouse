# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::DocumentExports::CellDetailExport, type: :model do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }) }
    let(:export) do
      described_class.create!(
        user: user,
        status: DocumentExportBehavior::PENDING_STATUS,
        query_string: {
          report_id: report.id,
          measure_id: 'Q1',
          cell_id: 'B2',
          table: 'Table 1',
        }.to_query,
      )
    end
    let(:result) do
      HudSpmReport::CellDetailExportBuilder::Result.new(
        name: 'SPM FY 2026 Q1 B2',
        filename: 'SPM FY 2026 Q1 B2 Cell Detail.xlsx',
        data: 'xlsx-bytes',
      )
    end

    it 'stores the generated file via the DocumentExport pipeline' do
      builder = instance_double(HudSpmReport::CellDetailExportBuilder, call: result)
      expect(HudSpmReport::CellDetailExportBuilder).
        to receive(:new).
        with(user: user, report: report, measure_id: 'Q1', cell_id: 'B2', table: 'Table 1').
        and_return(builder)

      export.perform
      export.reload

      expect(export.file_data).to eq('xlsx-bytes')
      expect(export.filename).to eq('SPM FY 2026 Q1 B2 Cell Detail.xlsx')
      expect(export.mime_type).to eq(DocumentExportBehavior::EXCEL_MIME_TYPE)
      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
    end
  end

  describe '#authorized?' do
    let(:owner) { create(:user) }
    let(:report) { create(:hud_reports_report_instance, user: owner) }
    let(:export) do
      described_class.create!(
        user: owner,
        status: DocumentExportBehavior::PENDING_STATUS,
        query_string: { report_id: report.id }.to_query,
      )
    end

    it 'requires proper HUD report permissions' do
      other_user = create(:user)
      owner.legacy_roles << create(:role, can_view_own_hud_reports: true)
      other_user.legacy_roles << create(:role, can_view_own_hud_reports: false)

      expect(export.authorized?).to be(true)
      export.user = other_user
      expect(export.authorized?).to be(false)
    end
  end
end
