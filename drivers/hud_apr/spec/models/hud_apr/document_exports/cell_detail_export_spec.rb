###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::DocumentExports::CellDetailExport, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }, report_name: HudApr::Generators::Apr::Fy2026::Generator.title) }
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

  let(:definition_url) { 'hud_reports/aprs' }

  it_behaves_like 'a hud cell detail export'

  describe 'request parameters that do not identify the report' do
    let(:caper_definition) do
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      GrdaWarehouse::WarehouseReports::ReportDefinition.find_by!(url: 'hud_reports/capers')
    end

    def export_with(query)
      described_class.new(user: user, query_string: { report_id: report.id, measure_id: 'Question 5', cell_id: 'B2', table: '5a' }.merge(query).to_query)
    end

    it 'refuses an unknown report_type instead of raising' do
      user.legacy_roles << create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true)
      expect(export_with(report_type: 'bogus').authorized?).to be false
    end

    it 'refuses a request with no report_type instead of raising' do
      user.legacy_roles << create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true)
      expect(export_with({}).authorized?).to be false
    end

    it 'refuses a report whose version has no generator instead of raising' do
      user.legacy_roles << create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true)
      report.update!(options: { 'report_version' => 'fy1999' })
      expect(export_with(report_type: 'apr').authorized?).to be false
    end

    it 'refuses an APR report requested as a CAPER by a user who holds only the CAPER definition' do
      user.legacy_roles << create(:role, can_view_assigned_reports: true)
      user.add_viewable(caper_definition)
      expect(export_with(report_type: 'caper').authorized?).to be false
    end
  end

  describe '#builder' do
    it 'initializes APR builder with correct parameters' do
      builder = export.send(:builder)

      expect(builder).to be_a(HudApr::CellDetailExportBuilder)
      # Test that it correctly identifies the generator via the builder
      expect(builder.generator_for_report).to eq(HudApr::Generators::Apr::Fy2026::Generator)
    end
  end
end
