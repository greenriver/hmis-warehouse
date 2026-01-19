# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::DocumentExports::CellDetailExport, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }, report_name: 'SPM - FY 2026') }
  let(:export) do
    described_class.new(
      user: user,
      query_string: {
        report_id: report.id,
        measure_id: 'Q1',
        cell_id: 'B2',
        table: 'Table 1',
      }.to_query,
    )
  end

  describe '#builder' do
    it 'initializes SPM builder with correct parameters' do
      builder = export.send(:builder)

      expect(builder).to be_a(HudSpmReport::CellDetailExportBuilder)
      expect(builder.instance_variable_get(:@user)).to eq(user)
      expect(builder.instance_variable_get(:@report)).to eq(report)
      expect(builder.instance_variable_get(:@measure_id)).to eq('Q1')
      expect(builder.instance_variable_get(:@cell_id)).to eq('B2')
      expect(builder.instance_variable_get(:@table)).to eq('Table 1')
    end
  end
end
