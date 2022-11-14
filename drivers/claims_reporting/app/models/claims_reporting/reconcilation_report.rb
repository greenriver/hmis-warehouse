###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'
require 'memoist'

module ClaimsReporting
  class ReconcilationReport
    extend Memoist

    attr_accessor :month, :aco_ids

    def initialize(month:, aco_ids: [])
      @month = month
      @aco_ids = aco_ids.select(&:present?) # filter out empty strings from forms etc
    end

    def report_date_range
      @month.beginning_of_month .. @month.end_of_month
    end

    def serializable_hash
      {
        aco_ids: aco_ids,
        month: month,
        latest_payment_report_upload: {
          original_filename: latest_payment_report_upload.original_filename,
          completed_at: latest_payment_report_upload.completed_at,
        },
        active_patient_count: active_patient_count,
        payment_detail_count: payment_details.count,
        patients_without_payments: patients_without_payments.map(&:to_param),
        payments_without_patients: payments_without_patients.map(&:to_param),
      }
    end

    def active_patient_count
      active_patients.count
    end

    def latest_payment_report_upload
      CpPaymentUpload.order(:completed_at).last
    end

    def active_patients
      scope = ::Health::Patient.where.not(client_id: nil).active_between(report_date_range.min, report_date_range.max)
      if aco_ids.any?
        scope = scope.where(
          id: ::Health::PatientReferral.where(accountable_care_organization_id: aco_ids).select(:patient_id),
        )
      end
      scope
    end

    def qa_count_for_patient(patient)
      patient_qas(patient.id).size
    end

    def qa_missing_enrollment_count_for_patient(patient)
      patient_qas(patient.id).reject do |qa|
        # This is logically QualifyingActivity#occurred_during_any_enrollment? but is
        # faster since we will already have the full patient_referrals history
        qa.date_of_activity.present? && patient.patient_referrals.detect do |r|
          r.active_on?(qa.date_of_activity)
        end
      end.size
    end

    def qa_missing_careplan_count_for_patient(patient)
      patient_qas(patient.id).select(&:missing_care_plan?).size
    end

    def careplan_dates_for_patient(patient)
      patient.careplans.select(&:provider_signed_on).map { |d| d.provider_signed_on.to_date }.to_sentence
    end

    def denied_claims(patient)
      patient_qas(patient.id).select { |qa| patient.best_medical_claim_for_qualifying_activity(qa, denied: true).present? }.size
    end

    def enrolled(patient)
      MedicalClaim.find_by(
        member_id: patient.medicaid_id,
        service_start_date: report_date_range,
      )&.enrolled_flag
    end

    def patients_without_payments
      active_patients.where.not(
        medicaid_id: payment_details.select(:medicaid_id),
      ).preload(:careplans, :qualifying_activities, patient_referrals: :aco)
    end

    private def patients_without_payments_by_id
      patients_without_payments.index_by(&:id)
    end
    memoize :patients_without_payments_by_id

    private def patient_qas(patient_id)
      qas = patients_without_payments_by_id[patient_id]&.qualifying_activities || []
      qas.select { |r| r.submitted? && report_date_range.cover?(r.date_of_activity) }
    end
    memoize :patient_qas

    def payments_without_patients
      payment_details.where.not(
        medicaid_id: active_patients.select(:medicaid_id),
      )
    end

    def payment_details
      CpPaymentDetail.where(
        paid_dos: report_date_range,
      )
    end

    def patients_without_payments_columns
      [
        'Medicaid ID',
        'Last Name',
        'First Name',
        'Submitted QAs',
        'QAs Outside Enrollment',
        'QAs Without Required Careplan',
        'Denied Claims',
        'Careplan PCP signatures',
        'Was Enrolled?',
      ]
    end

    def patients_without_payments_rows
      patients_without_payments.map do |patient|
        [
          patient.medicaid_id,
          patient.last_name,
          patient.first_name,
          qa_count_for_patient(patient),
          qa_missing_enrollment_count_for_patient(patient),
          qa_missing_careplan_count_for_patient(patient),
          denied_claims(patient),
          careplan_dates_for_patient(patient),
          enrolled(patient),
        ]
      end
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << patients_without_payments_columns
        patients_without_payments_rows.each do |row|
          csv << row
        end
      end
    end
  end
end
