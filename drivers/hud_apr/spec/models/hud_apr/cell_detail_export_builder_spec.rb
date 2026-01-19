###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::CellDetailExportBuilder, type: :model do
  let(:user) { create(:user) }
  let(:report) do
    create(:hud_reports_report_instance,
           user: user,
           options: { 'report_version' => 'fy2026' })
  end
  let(:builder) do
    described_class.new(
      user: user,
      report: report,
      measure_id: 'Question 5',
      cell_id: 'B2',
      table: '5a',
      report_type: 'apr'
    )
  end

  describe '#generator_for_report' do
    it 'returns the correct generator for APR FY2026' do
      expect(builder.generator_for_report).to eq(HudApr::Generators::Apr::Fy2026::Generator)
    end

    it 'returns the correct generator for CAPER FY2026' do
      b = described_class.new(user: user, report: report, report_type: 'caper')
      expect(b.generator_for_report).to eq(HudApr::Generators::Caper::Fy2026::Generator)
    end

    it 'returns the correct generator for CE APR FY2026' do
      b = described_class.new(user: user, report: report, report_type: 'ce_apr')
      expect(b.generator_for_report).to eq(HudApr::Generators::CeApr::Fy2026::Generator)
    end

    it 'returns the correct generator for DQ FY2026' do
      b = described_class.new(user: user, report: report, report_type: 'dq')
      expect(b.generator_for_report).to eq(HudApr::Generators::Dq::Fy2026::Generator)
    end

    it 'falls back to fy2020 if version is missing' do
      report.options = {}
      expect(builder.generator_for_report).to eq(HudApr::Generators::Apr::Fy2020::Generator)
    end

    it 'handles version strings with spaces and different casing' do
      report.options['report_version'] = 'FY 2024'
      expect(builder.generator_for_report).to eq(HudApr::Generators::Apr::Fy2024::Generator)
    end

    it 'raises ArgumentError for unknown report type' do
      b = described_class.new(user: user, report: report, report_type: 'invalid')
      expect { b.generator_for_report }.to raise_error(ArgumentError, /Unknown report type/)
    end
  end

  describe '#call' do
    it 'returns a Result object with XLSX data' do
      # Ensure base_scope is mockable or returns empty relation
      allow_any_instance_of(HudReports::DrilldownContext).to receive(:base_scope).and_return(HudApr::Fy2020::AprClient.none)

      result = builder.call

      expect(result).to be_a(HudApr::CellDetailExportBuilder::Result)
      expect(result.name).to be_present
      expect(result.filename).to end_with('.xlsx')
      expect(result.data).to be_present
      # Verify it's a valid zip (XLSX is a zip)
      expect(result.data[0..1]).to eq('PK')
    end
  end
end
