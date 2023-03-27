require 'rails_helper'

RSpec.describe Health::CareplanSaver, type: :model do
  let(:user) { create :user }
  let!(:provider) { create :provider }
  let!(:patient) { create :patient }
  let!(:careplan) { create :careplan, patient: patient, provider_id: provider.id }

  it 'creates a care planning QA when the patient signs, but not a PCTP signed one until the NCM and RN also signs' do
    careplan.patient_signed_on = Date.today
    Health::CareplanSaver.new(user: user, careplan: careplan, create_qa: true).update

    expect(Health::QualifyingActivity.where(activity: 'care_planning').exists?).to be true

    careplan.ncm_approval = true
    careplan.rn_approved_on = Date.today
    Health::CareplanSaver.new(user: user, careplan: careplan, create_qa: true).update

    expect(Health::QualifyingActivity.where(activity: 'pctp_signed').exists?).to be true
    expect(patient.qualifying_activities.count).to eq(2) # Doesn't add a second care planning QA
  end
end
