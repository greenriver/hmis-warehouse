require 'rails_helper'

RSpec.describe 'HRSN homeless changes', type: :model do
  let!(:patient) { create(:patient) }
  let!(:ssm) { create(:ssm, patient_id: patient.id, housing_score: 1) }
  let!(:ssm2) { create(:ssm, patient_id: patient.id, housing_score: 2) }
  let!(:cm_note) { create(:sdh_case_management_note, patient_id: patient.id) }

  it 'only create one qa' do
    expect(Health::QualifyingActivity.count).to eq 1
  end
end
