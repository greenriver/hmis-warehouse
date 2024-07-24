require 'rails_helper'

RSpec.describe 'Missing PCTP Component QAs', type: :model do
  let!(:user) { create(:user) }
  let!(:sender) { create(:sender) }
  let!(:patient) { create(:patient) }
  let!(:claim) { create :health_claim }

  describe 'has all the components' do
    let!(:thrive) { create :thrive, user_id: user.id, patient_id: patient.id }
    let!(:hrsn) { create :hrsn_screening, instrument: thrive, patient_id: patient.id }
    let!(:ca_instrument) { create :health_ca, user_id: user.id, patient_id: patient.id }
    let!(:ca) { create :ca_assessment, instrument: ca_instrument, patient_id: patient.id }
    let!(:careplan) do
      create :cp2_careplan,
             user_id: user.id, patient_id: patient.id,
             patient_signed_on: Date.current,
             reviewed_by_ccm_on: Date.current, reviewed_by_ccm_id: user.id,
             reviewed_by_rn_on: Date.current, reviewed_by_rn_id: user.id
    end
    let!(:pctp) { create :pctp_careplan, instrument: careplan, patient_id: patient.id }

    it 'has all the QAs' do
      qa_factory = patient.current_qa_factory
      qa_factory.complete_hrsn(hrsn.instrument)
      qa_factory.complete_ca(ca.instrument)
      qa_factory.complete_careplan(pctp.instrument)
      qa_factory.review_careplan(pctp.instrument)
      qa_factory.approve_careplan(pctp.instrument)

      expect(qa_factory.missing_components?).to be false
    end
  end

  describe 'is missing a component' do
    # let!(:thrive) { create :thrive, user_id: user.id, patient_id: patient.id }
    # let!(:hrsn) { create :hrsn_screening, instrument: thrive, patient_id: patient.id }
    let!(:ca_instrument) { create :health_ca, user_id: user.id, patient_id: patient.id }
    let!(:ca) { create :ca_assessment, instrument: ca_instrument, patient_id: patient.id }
    let!(:careplan) do
      create :cp2_careplan,
             user_id: user.id, patient_id: patient.id,
             patient_signed_on: Date.current,
             reviewed_by_ccm_on: Date.current, reviewed_by_ccm_id: user.id,
             reviewed_by_rn_on: Date.current, reviewed_by_rn_id: user.id
    end
    let!(:pctp) { create :pctp_careplan, instrument: careplan, patient_id: patient.id }

    it 'is missing a QA' do
      qa_factory = patient.current_qa_factory
      # qa_factory.complete_hrsn(hrsn.instrument)
      qa_factory.complete_ca(ca.instrument)
      qa_factory.complete_careplan(pctp.instrument)
      qa_factory.review_careplan(pctp.instrument)
      qa_factory.approve_careplan(pctp.instrument)

      expect(qa_factory.missing_components?).to be true
    end
  end
end
