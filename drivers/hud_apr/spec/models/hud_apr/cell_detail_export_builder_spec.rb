###
# Copyright Green River Data Group, Inc.
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
      report_type: 'apr',
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

    it 'exports every client in the cell when more clients than the preload miss threshold are in it' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
      GrdaWarehouse::Config.invalidate_cache
      cell = report.report_cells.create!(question: '5a', cell_name: 'B2')
      clients = Array.new(preload_miss_client_count) do |i|
        destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{i}", LastName: 'Coverage')
        apr_client = create(:hud_report_apr_client, report_instance: report, client_id: destination.id, destination_client_id: destination.id, first_name: destination.FirstName, last_name: destination.LastName)
        HudReports::UniverseMember.create!(report_cell: cell, universe_membership: apr_client, client_id: destination.id)
        destination
      end

      values = xlsx_cell_values(builder.call.data)

      clients.each { |client| expect(values).to include(client.FirstName) }
    end
  end
end
