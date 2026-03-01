###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::DocumentExports::CellDetailExport, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }, report_name: 'APR - FY 2026') }
  let(:export) do
    described_class.new(
      user: user,
      query_string: {
        report_id: report.id,
        measure_id: 'Question 5',
        cell_id: 'B2',
        table: '5a',
        report_type: 'apr',
      }.to_query,
    )
  end

  it_behaves_like 'a hud cell detail export'

  describe '#builder' do
    it 'initializes APR builder with correct parameters' do
      builder = export.send(:builder)

      expect(builder).to be_a(HudApr::CellDetailExportBuilder)
      # Test that it correctly identifies the generator via the builder
      expect(builder.generator_for_report).to eq(HudApr::Generators::Apr::Fy2026::Generator)
    end
  end
end
