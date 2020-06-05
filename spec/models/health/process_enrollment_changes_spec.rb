require 'rails_helper'

RSpec.describe Health::ProcessEnrollmentChangesJob, type: :model do
  let!(:health_data_source) { create :health_data_source }
  let!(:destination_data_source) { create :destination_data_source }
  let!(:referral_ds) { create :referral_ds }
  let!(:receiver) { create :receiver }

  it 'enrolls a new patient' do
    referrals = Health::PatientReferral.current.count

    process('enrollment.txt')

    expect(Health::PatientReferral.current.count).to eq(referrals + 1)
  end

  it 'does not duplicate enrollments' do
    referrals = Health::PatientReferral.current.count

    process('enrollment.txt')
    process('enrollment.txt')

    expect(Health::PatientReferral.current.count).to eq(referrals + 1)
  end

  it 'ignores disenrollment of non-existent patient' do
    process('disenrollment.txt')
    expect(Health::PatientReferral.pending_disenrollment.count).to eq(0)
  end

  it 'marks existing patient as pending disenrollment' do
    pending = Health::PatientReferral.pending_disenrollment.count

    process('enrollment.txt')
    process('disenrollment.txt')

    expect(Health::PatientReferral.pending_disenrollment.count).to eq(pending + 1)
  end

  it 're-enrolls a disenrolled patient' do
    process('enrollment.txt')
    process('disenrollment.txt')

    pending = Health::PatientReferral.pending_disenrollment.count

    process('reenrollment.txt')

    expect(Health::PatientReferral.pending_disenrollment.count).to eq(pending - 1)
  end

  it 'updates a patient' do
    process('enrollment.txt')
    process('update_name.txt')

    expect(Health::PatientReferral.where(medicaid_id: '100000000999').count).to eq(2)
    expect(Health::PatientReferral.where(medicaid_id: '100000000999', current: true).count).to eq(1)
    expect(Health::PatientReferral.find_by(medicaid_id: '100000000999', current: true).first_name).to eq('ARIEL')
  end

  it 'updates a patient, preserving agency' do
    process('enrollment.txt')
    Health::PatientReferral.find_by(medicaid_id: '100000000999', current: true).update(agency_id: 123)

    process('update_name.txt')

    expect(Health::PatientReferral.where(medicaid_id: '100000000999').count).to eq(2)
    expect(Health::PatientReferral.where(medicaid_id: '100000000999', current: true).count).to eq(1)
    expect(Health::PatientReferral.find_by(medicaid_id: '100000000999', current: true).agency_id).to eq(123)
  end

  it 'updates a patient, clearing agency' do
    process('enrollment.txt')
    Health::PatientReferral.find_by(medicaid_id: '100000000999', current: true).update(agency_id: 123)

    process('update_enrollment_start_date.txt')

    expect(Health::PatientReferral.where(medicaid_id: '100000000999').count).to eq(2)
    expect(Health::PatientReferral.where(medicaid_id: '100000000999', current: true).count).to eq(1)
    expect(Health::PatientReferral.find_by(medicaid_id: '100000000999', current: true).agency_id).to eq(nil)
  end

  def process(fixture)
    file = Health::Enrollment.create(
      content: File.read("spec/fixtures/files/health/eight_thirty_four/#{fixture}"),
    )
    Health::ProcessEnrollmentChangesJob.new.perform(file.id)
  end
end
