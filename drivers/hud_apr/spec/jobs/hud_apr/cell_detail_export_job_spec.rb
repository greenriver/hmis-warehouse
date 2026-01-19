###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
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
             report_type: 'apr'
           }.to_query)
  end

  describe '#perform' do
    it 'executes the export and notifies the user' do
      mailer = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      allow(NotifyUser).to receive(:report_completed).and_return(mailer)

      # Mock the builder to avoid generating real XLSX and complex dependencies
      builder = instance_double(HudApr::CellDetailExportBuilder)
      drilldown = instance_double(HudReports::DrilldownContext, name: 'Q5 B2')
      result = HudApr::CellDetailExportBuilder::Result.new(
        name: 'Q5 B2',
        filename: 'q5_b2.xlsx',
        data: 'xlsx-data'
      )

      allow(HudApr::CellDetailExportBuilder).to receive(:new).and_return(builder)
      allow(builder).to receive(:call).and_return(result)
      allow(builder).to receive(:drilldown).and_return(drilldown)

      described_class.perform_now(export_id: export.id)

      export.reload
      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
      expect(export.file_data).to eq('xlsx-data')
      expect(export.filename).to eq('q5_b2.xlsx')

      expect(NotifyUser).to have_received(:report_completed).with(
        user.id,
        have_attributes(
          title: 'Q5 B2 Cell Detail',
          url: match(/\/document_exports\/\d+\/download/)
        )
      )
      expect(mailer).to have_received(:deliver_now)
    end

    it 'handles export failure gracefully via DocumentExportJobBehavior' do
      # If the job fails, DocumentExportJobBehavior should handle it
      builder = instance_double(HudApr::CellDetailExportBuilder)
      allow(HudApr::CellDetailExportBuilder).to receive(:new).and_return(builder)
      allow(builder).to receive(:call).and_raise(StandardError, 'Something went wrong')

      expect {
        described_class.perform_now(export_id: export.id)
      }.to raise_error(StandardError, 'Something went wrong')

      expect(export.reload.status).to eq(DocumentExportBehavior::ERROR_STATUS)
    end
  end
end
