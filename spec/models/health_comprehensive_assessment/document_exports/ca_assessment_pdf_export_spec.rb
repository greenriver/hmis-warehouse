###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthComprehensiveAssessment::DocumentExports::CaAssessmentPdfExport, type: :model do
  let(:user) { create(:acl_user) }
  let(:patient) { create(:patient) }
  let(:assessment) { create(:health_ca, patient: patient, user: user) }
  let(:fake_pdf) { '%PDF-1.4 fake' }
  let(:merged_pdf) { '%PDF-1.4 merged' }

  before do
    allow(PdfGenerator).to receive(:html).and_return('<html/>')
    allow(PdfGenerator).to receive(:render_pdf).and_return(fake_pdf)
    allow(PdfGenerator).to receive(:merge_inline_pdfs).and_return(merged_pdf)
  end

  describe '.generate' do
    it 'returns merged PDF binary data' do
      result = described_class.generate(user: user, assessment: assessment)
      expect(result).to eq(merged_pdf)
    end

    it 'calls render_pdf at least twice' do
      described_class.generate(user: user, assessment: assessment)
      expect(PdfGenerator).to have_received(:render_pdf).at_least(:twice)
    end

    it 'merges the first page and body PDFs' do
      described_class.generate(user: user, assessment: assessment)
      expect(PdfGenerator).to have_received(:merge_inline_pdfs).with([fake_pdf, fake_pdf])
    end
  end
end
