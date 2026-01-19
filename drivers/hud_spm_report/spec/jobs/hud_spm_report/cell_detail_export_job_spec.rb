# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::CellDetailExportJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }) }
    let(:export) do
      HudSpmReport::DocumentExports::CellDetailExport.create!(
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
    let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

    before do
      allow(NotifyUser).to receive(:report_completed).and_return(mailer)
      # allow_any_instance_of(HudSpmReport::DocumentExports::CellDetailExport).to receive(:download_url).and_return('https://example.com/download/123')
    end

    it 'runs the document export and notifies the user' do
      described_class.perform_now(export_id: export.id)

      export.reload

      expect(export.file_data).to be_present
      expect(export.filename).to end_with('.xlsx')
      expect(export.mime_type).to eq(DocumentExportBehavior::EXCEL_MIME_TYPE)
      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
      expect(NotifyUser).to have_received(:report_completed).with(
        user.id,
        have_attributes(
          title: 'SPM FY 2026: Q1 / Table Table 1 / Cell B2 Cell Detail',
          url: match(/\/document_exports\/\d+\/download/),
        ),
      )
      expect(mailer).to have_received(:deliver_now)
    end
  end
end
