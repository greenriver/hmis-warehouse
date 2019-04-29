require 'rails_helper'

RSpec.describe Health::FlagIneligiblePatientsJob, type: :model do
  let!(:sender) { create :sender }

  let!(:patient_01) { create :patient, medicaid_id: 'ID01' } # EB 6 in fixture
  let!(:patient_02) { create :patient, medicaid_id: 'ID02' } # EB 1, EB X in fixture
  let!(:patient_03) { create :patient, medicaid_id: 'ID03' } # EB 1, EB L in fixture
  let!(:patient_04) { create :patient, medicaid_id: 'ID04' }

  let!(:inquiry) { create :eligibility_inquiry }
  let!(:response) { create :eligibility_response, eligibility_inquiry: inquiry, response: read_fixture }

  it 'processes the fixture' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)
    patient_01.reload

    expect(patient_01.coverage_inquiry_date).to eq Date.today
  end

  it 'does not process other patients' do
    patient_04.reload

    expect(patient_01.coverage_inquiry_date).to be nil
  end

  it 'flags ineligible patients' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)

    expect(Health::Patient.no_coverage).to include patient_01
    expect(Health::Patient.no_coverage).not_to include patient_02, patient_03
  end

  it 'flags standard patients' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)

    expect(Health::Patient.standard_coverage).to include patient_02
    expect(Health::Patient.standard_coverage).not_to include patient_01, patient_03
  end

  it 'flags managed patients' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)

    expect(Health::Patient.program_ineligible).not_to include patient_03
    expect(Health::Patient.program_ineligible).to include patient_01, patient_02
  end

  def read_fixture
    File.read('spec/fixtures/files/health/eligibility/response.txt')
  end
end
