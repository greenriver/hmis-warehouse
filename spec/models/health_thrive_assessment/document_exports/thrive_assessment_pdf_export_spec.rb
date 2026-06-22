###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthThriveAssessment::DocumentExports::ThriveAssessmentPdfExport, type: :model do
  let(:user) { create(:acl_user) }
  let(:patient) { create(:patient) }
  let(:thrive) { create(:thrive, patient: patient, user: user) }

  before do
    fake_pdf = '%PDF-1.4 fake'
    allow(PdfGenerator).to receive(:html).and_return('<html/>')
    allow(PdfGenerator).to receive(:render_pdf).and_return(fake_pdf)
  end

  describe '.generate' do
    it 'returns PDF binary data' do
      result = described_class.generate(user: user, assessment: thrive)
      expect(result).to eq('%PDF-1.4 fake')
    end
  end
end
