require 'rails_helper'

RSpec.describe Health::CareplanSaver, type: :model do
  let(:user) { create :user }
  let!(:provider) { create :provider }
  let!(:patient) { create :patient }
  let!(:careplan) { create :careplan, patient: patient, provider_id: provider.id }

  it 'creates a "mode of contact is other" QA if the careplan is signed via email' do
    careplan.provider_signed_on = Date.today
    careplan.provider_signature_mode = :email
    careplan.patient_signed_on = Date.today
    careplan.patient_signature_mode = :email

    Health::CareplanSaver.new(user: user, careplan: careplan, create_qa: true).update

    expect(Health::QualifyingActivity.where(activity: 'pctp_signed', mode_of_contact: 'other').exists?).to be true
  end

  it 'creates a "mode of contact is in person" QA if the careplan is signed in person' do
    careplan.provider_signed_on = Date.today
    careplan.provider_signature_mode = :in_person
    careplan.patient_signed_on = Date.today
    careplan.patient_signature_mode = :email

    Health::CareplanSaver.new(user: user, careplan: careplan, create_qa: true).update

    expect(Health::QualifyingActivity.where(activity: 'pctp_signed', mode_of_contact: 'in_person').exists?).to be true
  end

  it "doesn't create a QA if the careplan is incomplete" do
    careplan.provider_signed_on = Date.today
    careplan.provider_signature_mode = :email

    Health::CareplanSaver.new(user: user, careplan: careplan, create_qa: true).update

    expect(Health::QualifyingActivity.where(activity: 'pctp_signed').exists?).to be false
  end
end
