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

  it_behaves_like 'a hud cell detail export'

  describe '#builder' do
    it 'initializes SPM builder with correct parameters' do
      builder = export.send(:builder)

      expect(builder).to be_a(HudSpmReport::CellDetailExportBuilder)
      # We test behavior by checking if the builder is correctly configured for the report
      expect(builder.generator_for_report).to eq(HudSpmReport::Generators::Fy2026::Generator)
    end
  end
end
