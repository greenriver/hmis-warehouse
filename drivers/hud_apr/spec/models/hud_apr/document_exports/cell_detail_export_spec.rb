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

  describe '#builder' do
    it 'initializes APR builder with correct parameters' do
      builder = export.send(:builder)

      expect(builder).to be_a(HudApr::CellDetailExportBuilder)
      expect(builder.instance_variable_get(:@user)).to eq(user)
      expect(builder.instance_variable_get(:@report)).to eq(report)
      expect(builder.instance_variable_get(:@measure_id)).to eq('Question 5')
      expect(builder.instance_variable_get(:@cell_id)).to eq('B2')
      expect(builder.instance_variable_get(:@table)).to eq('5a')
      expect(builder.instance_variable_get(:@report_type)).to eq('apr')
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
