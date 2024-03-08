require 'rails_helper'

RSpec.describe 'HRSN homeless changes', type: :model do
  let!(:patient) { create(:patient) }
  # Give patient a housing status history
  let!(:ssm) { create(:ssm, patient_id: patient.id, housing_score: 0, completed_at: Date.yesterday) }
  # Make patient engaged
  let!(:cp2_careplan) { create(:cp2_careplan, patient_id: patient.id, sent_to_pcp_on: Date.current) }
  let!(:pctp_careplan) { create(:pctp_careplan, instrument: cp2_careplan, patient_id: patient.id) }
  let!(:ssm2) { create(:ssm, patient_id: patient.id, housing_score: 1) }
  let!(:ssm3) { create(:ssm, patient_id: patient.id, housing_score: 2) }
  let!(:cm_note) { create(:sdh_case_management_note, patient_id: patient.id) }

  it 'only create one qa' do
    expect(Health::QualifyingActivity.count).to eq 1
  end
end
