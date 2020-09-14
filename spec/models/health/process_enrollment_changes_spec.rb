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
    expect(Health::PatientReferral.current.where(record_status: 'A').count).to eq(referrals + 1)
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
    expect(Health::PatientReferral.pending_disenrollment.where(record_status: 'I').count).to eq(pending + 1)
  end

  it 're-enrolls a disenrolled patient' do
    process('enrollment.txt')
    process('disenrollment.txt')

    pending = Health::PatientReferral.pending_disenrollment.count

    process('reenrollment.txt')

    expect(Health::PatientReferral.pending_disenrollment.count).to eq(pending - 1)
  end

  it 'ignores a re-enrollment that is too soon' do
    process('enrollment.txt')
    process('disenrollment.txt')

    Health::PatientReferral.pending_disenrollment.each do |referral|
      referral.update(
        removal_acknowledged: true,
        disenrollment_date: referral.pending_disenrollment_date,
        pending_disenrollment_date: nil,
      )
    end

    process('reenrollment.txt')

    expect(Health::PatientReferral.rejection_confirmed.count).to eq(1)
    expect(Health::Enrollment.last.processing_errors.length).to be > 0
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

  describe 'conflicting medicaid ids' do
    let!(:existing_patient) { create :patient, medicaid_id: '100000000999' }

    it 'identifies conflicting medicaid ids' do
      process('enrollment.txt')

      expect(Health::Enrollment.last.processing_errors.length).to be > 0
    end
  end

  def process(fixture)
    file = Health::Enrollment.create(
      content: File.read("spec/fixtures/files/health/eight_thirty_four/#{fixture}"),
    )
    Health::ProcessEnrollmentChangesJob.new.perform(file.id)
  end
end
