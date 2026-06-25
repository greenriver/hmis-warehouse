###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthPctp::DocumentExports::PctpCareplanPdfExport, type: :model do
  let(:careplan) { create(:cp2_careplan) }
  let(:user) { careplan.user }
  let(:fake_pdf) { '%PDF-1.4 fake' }
  let(:merged_pdf) { '%PDF-1.4 merged' }

  before do
    allow(PdfGenerator).to receive(:html).and_return('<html/>')
    allow(PdfGenerator).to receive(:render_pdf).and_return(fake_pdf)
    allow(PdfGenerator).to receive(:merge_inline_pdfs).and_return(merged_pdf)
  end

  describe '.generate' do
    it 'returns merged PDF binary data' do
      result = described_class.generate(user: user, careplan: careplan)
      expect(result).to eq(merged_pdf)
    end

    it 'renders a coverpage and body PDF and merges them' do
      described_class.generate(user: user, careplan: careplan)
      expect(PdfGenerator).to have_received(:render_pdf).at_least(:twice)
      expect(PdfGenerator).to have_received(:merge_inline_pdfs).with(
        array_including(fake_pdf, fake_pdf),
      )
    end

    it 'does not append health_file when absent' do
      described_class.generate(user: user, careplan: careplan)
      expect(PdfGenerator).to have_received(:merge_inline_pdfs).with(
        [fake_pdf, fake_pdf],
      )
    end
  end
end
