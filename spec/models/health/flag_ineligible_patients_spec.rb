require 'rails_helper'

RSpec.describe Health::FlagIneligiblePatientsJob, type: :model do
  let!(:sender) { create :sender }

  let!(:patient_01) { create :patient, medicaid_id: 'ID01' } # EB 6, in fixture, error 42
  let!(:patient_02) { create :patient, medicaid_id: 'ID02' } # EB 1, EB X, in fixture
  let!(:patient_03) { create :patient, medicaid_id: 'ID03' } # EB 1, EB MC, in fixture
  let!(:patient_04) { create :patient, medicaid_id: 'ID04' } # EB 1, EB L, in fixture, error 72
  let!(:patient_05) { create :patient, medicaid_id: 'ID05' } # not in fixture
  let!(:patient_06) { create :patient, medicaid_id: 'ID06' } # EB 1, EB MC, EB R MEDICARE A, in fixture

  let!(:inquiry) { create :eligibility_inquiry }
  let!(:response) { create :eligibility_response, eligibility_inquiry: inquiry, response: read_fixture }

  it 'processes the fixture' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)
    patient_02.reload

    expect(patient_02.coverage_inquiry_date).to eq Date.current
  end

  it 'does not process other patients' do
    patient_05.reload

    expect(patient_05.coverage_inquiry_date).to be nil
  end

  it 'does not process patients with errors' do
    patient_01.reload

    expect(patient_01.coverage_inquiry_date).to be nil
  end

  it 'flags ineligible patients' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)

    expect(Health::Patient.no_coverage).to include patient_06
    expect(Health::Patient.no_coverage).not_to include patient_01, patient_02, patient_03, patient_04, patient_05
  end

  it 'flags standard patients' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)

    expect(Health::Patient.standard_coverage).to include patient_02
    expect(Health::Patient.standard_coverage).not_to include patient_03, patient_06 # MC
    expect(Health::Patient.standard_coverage).not_to include patient_01 # no coverage
    expect(Health::Patient.standard_coverage).not_to include patient_04 # invalid id
  end

  it 'flags managed patients' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)

    expect(Health::Patient.program_ineligible).not_to include patient_03
    expect(Health::Patient.program_ineligible).to include patient_02, patient_06
    expect(Health::Patient.program_ineligible).to_not include patient_01 # error
    expect(Health::Patient.program_ineligible).not_to include patient_04 # invalid id
  end

  it 'labels managed patients with org name' do
    Health::FlagIneligiblePatientsJob.new.perform(inquiry.id)

    # Get patient data from DB
    patient_03.reload

    expect(patient_03.aco_name).to eq 'ACO NAME'
  end

  def read_fixture
    File.read('spec/fixtures/files/health/eligibility/response.txt')
  end
end
