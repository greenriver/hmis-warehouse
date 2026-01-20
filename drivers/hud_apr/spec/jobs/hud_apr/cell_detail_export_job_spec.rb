###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::CellDetailExportJob, type: :job do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user) }
  let(:export) do
    HudApr::DocumentExports::CellDetailExport.create!(
      user: user,
      status: DocumentExportBehavior::PENDING_STATUS,
      query_string: {
        report_id: report.id,
        measure_id: 'Question 5',
        cell_id: 'B2',
        table: '5a',
        report_type: 'apr',
      }.to_query,
    )
  end

  describe '#perform' do
    it 'uses correct export scope' do
      expect(described_class.new.send(:export_scope)).to eq(HudApr::DocumentExports::CellDetailExport)
    end
  end
end
