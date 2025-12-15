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
    let(:builder) { instance_double(HudSpmReport::CellDetailExportBuilder) }
    let(:result) do
      HudSpmReport::CellDetailExportBuilder::Result.new(
        name: 'SPM FY 2026 Q1 B2',
        filename: 'SPM FY 2026 Q1 B2 Cell Detail.xlsx',
        data: 'xlsx-bytes',
      )
    end
    let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

    before do
      allow(HudSpmReport::CellDetailExportBuilder).to receive(:new).and_return(builder)
      allow(builder).to receive(:call).and_return(result)
      allow(NotifyUser).to receive(:report_completed).and_return(mailer)
    end

    it 'runs the document export and notifies the user' do
      described_class.perform_now(export_id: export.id)

      export.reload

      expect(builder).to have_received(:call)
      expect(export.file_data).to eq('xlsx-bytes')
      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
      expect(NotifyUser).to have_received(:report_completed).with(user.id, have_attributes(title: 'SPM Cell Detail – Q1 B2', url: export.download_url))
      expect(mailer).to have_received(:deliver_now)
    end
  end
end
