require 'rails_helper'

RSpec.describe 'ClaimsReporting::ReconcilationReport', type: :model do
  it 'works' do
    # done as one big example since we need all sorts of state setup and torn down
    # and with terser mini test assertions so we can have helpful output per assertion

    month = Date.iso8601('2020-06-15')
    # old_patients
    (1..3).map do |_n|
      end_date = month.beginning_of_month - 1.day
      create(:patient,
             patient_referral: create(:prior_referral,
                                      disenrollment_date: end_date,
                                      enrollment_start_date: end_date - 1.year))
    end

    active_patients = (1..10).map do |_n|
      create(:patient,
             patient_referral: create(:prior_referral,
                                      enrollment_start_date: month.beginning_of_month - 1.day,
                                      disenrollment_date: month.end_of_month))
    end

    # active careplan
    # unsigned careplan
    # expired careplan

    ClaimsReporting::CpPaymentUpload.new.save(
      validate: false,
    )

    report = ClaimsReporting::ReconcilationReport.new(
      month: month,
    )

    # it 'covers the expected month' do
    expect(report.report_date_range.first).to eq(month.beginning_of_month)
    expect(report.report_date_range.last).to eq(month.end_of_month)

    # 'has active patients' do
    expect(report.active_patient_count).to eq(active_patients.size)
    assert_equal active_patients.map(&:id).to_set, report.active_patients.map(&:id).to_set, 'finds active patients'

    # it 'knows the latest_payment_report_upload' do
    expect(report.latest_payment_report_upload.class).to eq(ClaimsReporting::CpPaymentUpload)

    patient = active_patients.first

    assert_equal 0, report.qa_count_for_patient(patient), 'qa_count_for_patient'
    assert_equal 0, report.qa_missing_enrollment_count_for_patient(patient), 'qa_missing_enrollment_count_for_patient'
    assert_equal 0, report.qa_missing_careplan_count_for_patient(patient), 'qa_missing_careplan_count_for_patient'
    assert_equal 0, report.careplan_dates_for_patient(patient).size, 'careplan_dates_for_patient'

    assert_instance_of Array, report.patients_without_payments_columns, 'patients_without_payments_columns'
    assert_instance_of Array, report.patients_without_payments_columns, 'patients_without_payments_rows'
    assert_instance_of String, report.to_csv, 'can make a CSV string'
  end
end
