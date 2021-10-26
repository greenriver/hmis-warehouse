###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'ClaimsReporting::ReconcilationReport', type: :model do
  it 'works' do
    # Done as one big example since we need all sorts of state setup
    # and torn down. And with terser mini test assertions so we can
    # have helpful output per assertion since this is a single Example

    month = Date.iso8601('2020-06-15')
    claim_submitted_on = month >> 2
    active_patients = []
    engagement_days = ::Health::PatientReferral::ENGAGEMENT_IN_DAYS.days
    # | QA occurs...
    # 0. before enrollment
    create(:patient).tap do |patient|
      referral = create(:prior_referral,
                        patient: patient,
                        enrollment_start_date: month.beginning_of_month + 15.days,
                        disenrollment_date: month.beginning_of_month + 15.days)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: referral.enrollment_start_date - 1.day,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 1, 0, []]
    end
    # 1. during grace period
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - 30.days,
             disenrollment_date: month.end_of_month)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 1.day,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 0, []]
    end
    # 2. after grace period, before  dis-enrollment, no careplan
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             disenrollment_date: month.end_of_month)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 11.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 1, []]
    end
    # 3. after grace period, before pending dis-enrollment, careplan missing signature
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             pending_disenrollment_date: month.end_of_month,
             disenrollment_date: nil)
      create(:careplan, patient: patient)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 11.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 1, []]
    end
    # 4. after grace period, before pending dis-enrollment, after careplan signed by engagement period end
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             pending_disenrollment_date: month.end_of_month,
             disenrollment_date: nil)
      cp = create(:careplan, patient: patient, provider_signed_on: month.beginning_of_month, provider_signature_mode: :in_person)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 11.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 0, [cp.provider_signed_on.to_date]]
    end
    # 5. after grace period, before pending dis-enrollment, after careplan signed after engagement period
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             pending_disenrollment_date: month.end_of_month,
             disenrollment_date: nil)
      cp = create(:careplan, patient: patient, provider_signed_on: month.beginning_of_month + 11.days, provider_signature_mode: :in_person)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 15.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 0, [cp.provider_signed_on.to_date]]
    end
    # 6. after grace period, before pending dis-enrollment, before careplan signed after engagement period
    # this is ok because if a careplan is signed it covers other activities in the plan (but not itself)
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             pending_disenrollment_date: month.end_of_month,
             disenrollment_date: nil)
      cp = create(:careplan, patient: patient, provider_signed_on: month.beginning_of_month + 15.days, provider_signature_mode: :in_person)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 11.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 0, [cp.provider_signed_on.to_date]]
    end
    # 7. after pending disenrollment before actual disenrollment, after valid careplan
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             pending_disenrollment_date: month.beginning_of_month + 10.days,
             disenrollment_date: month.end_of_month)
      cp = create(:careplan, patient: patient, provider_signed_on: month.beginning_of_month, provider_signature_mode: :in_person)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 15.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 0, [cp.provider_signed_on.to_date]]
    end
    # 8. during an open/current enrollment more than a year after last signed careplan
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             pending_disenrollment_date: nil,
             disenrollment_date: nil)
      cp = create(:careplan, patient: patient, provider_signed_on: month.beginning_of_month - 2.years, provider_signature_mode: :in_person)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 15.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 1, [cp.provider_signed_on.to_date]]
    end
    # 9. after disenrollment
    create(:patient).tap do |patient|
      referral = create(:prior_referral,
                        patient: patient,
                        enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
                        disenrollment_date: month.beginning_of_month + 10.days)
      cp = create(:careplan, patient: patient, provider_signed_on: referral.enrollment_start_date + 1.days, provider_signature_mode: :in_person)
      create(:qualifying_activity,
             patient: patient,
             date_of_activity: month.beginning_of_month + 15.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 1, 0, [cp.provider_signed_on.to_date]]
    end
    # 10. after grace period, before pending dis-enrollment, creating a careplan after engagement period
    # this is not payable and should be considered as a missed care plan
    create(:patient).tap do |patient|
      create(:prior_referral,
             patient: patient,
             enrollment_start_date: month.beginning_of_month - (engagement_days - 10.days),
             pending_disenrollment_date: month.end_of_month,
             disenrollment_date: nil)
      cp = create(:careplan, patient: patient, provider_signed_on: month.beginning_of_month + 15.days, provider_signature_mode: :in_person)
      create(:qualifying_activity,
             patient: patient,
             activity: 'care_planning',
             date_of_activity: month.beginning_of_month + 11.days,
             claim_submitted_on: claim_submitted_on)
      active_patients << [patient, 0, 1, [cp.provider_signed_on.to_date]]
    end
    # 11. after grace period, before pending dis-enrollment, an expired signed careplan after engagement period
    # this is not payable and should be considered as a missed care plan
    # 8/3/2021 -- JS asked that careplan expiration dates be ignored when deciding if it was missing., so this test case doesn't apply
    # create(:patient).tap do |patient|
    #   referral = create(:prior_referral,
    #                     patient: patient,
    #                     enrollment_start_date: month.beginning_of_month - 2.years,
    #                     pending_disenrollment_date: month.end_of_month,
    #                     disenrollment_date: nil)
    #   cp = create(:careplan,
    #               patient: patient,
    #               provider_signed_on: referral.enrollment_start_date,
    #               provider_signature_mode: :in_person,
    #               patient_signed_on: referral.enrollment_start_date,
    #               patient_signature_mode: :in_person)
    #   create(:qualifying_activity,
    #          patient: patient,
    #          date_of_activity: month.beginning_of_month + 11.days,
    #          claim_submitted_on: claim_submitted_on)
    #   active_patients << [patient, 0, 1, [cp.provider_signed_on.to_date]]
    # end

    ClaimsReporting::CpPaymentUpload.new.save(
      validate: false,
    )

    report = ClaimsReporting::ReconcilationReport.new(
      month: month,
    )
    # end of example setup...

    # it 'covers the expected month' do
    expect(report.report_date_range.first).to eq(month.beginning_of_month)
    expect(report.report_date_range.last).to eq(month.end_of_month)

    # 'has active patients' do
    expect(report.active_patient_count).to eq(active_patients.size)

    # it 'knows the latest_payment_report_upload' do
    expect(report.latest_payment_report_upload.class).to eq(ClaimsReporting::CpPaymentUpload)

    active_patients.each_with_index do |(patient, missing_enrollment, missing_cp, pcp_dates), idx|
      assert_equal 1, report.qa_count_for_patient(patient), "qa_count_for_patient(#{idx})"
      assert_equal missing_enrollment, report.qa_missing_enrollment_count_for_patient(patient), "qa_missing_enrollment_count_for_patient(#{idx})"
      assert_equal missing_cp, report.qa_missing_careplan_count_for_patient(patient), "qa_missing_careplan_count_for_patient(#{idx})"
      assert_equal pcp_dates&.to_sentence, report.careplan_dates_for_patient(patient), "careplan_dates_for_patient(#{idx})"
    end

    assert_instance_of Array, report.patients_without_payments_rows, 'patients_without_payments_rows'
    assert_equal active_patients.size, report.patients_without_payments_rows.size, 'patients_without_payments_rows'
    assert_instance_of Array, CSV.parse(report.to_csv), 'can make a CSV'
  end
end
