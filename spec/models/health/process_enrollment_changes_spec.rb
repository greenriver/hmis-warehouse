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

  def process(fixture)
    file = Health::Enrollment.create(
      content: File.read("spec/fixtures/files/health/eight_thirty_four/#{fixture}"),
    )
    Health::ProcessEnrollmentChangesJob.new.perform(file.id)
  end
end
