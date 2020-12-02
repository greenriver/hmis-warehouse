module ClaimsReporting
  class ReconcilationReport
    attr_accessor :month
    attr_accessor :aco_ids

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
      scope = ::Health::Patient.active_between(report_date_range.min, report_date_range.max)
      if aco_ids.any?
        scope = scope.where(
          id: ::Health::PatientReferral.where(accountable_care_organization_id: aco_ids).select(:patient_id),
        )
      end
      scope
    end

    def qa_count_for_patient(patient)
      qualifying_activities_by_patient_id[patient.id]&.size
    end

    def qa_missing_enrollment_count_for_patient(patient)
      qualifying_activities_by_patient_id[patient.id].reject do |qa|
        # This is logically occurred_during_any_enrollment? but is
        # faster since we will already have the full patient_referrals history
        qa.date_of_activity.present? && patient.patient_referrals.select do |r|
          r.active_on?(qa.date_of_activity)
        end
      end
    end

    def qa_missing_careplan_count_for_patient(patient)
      qualifying_activities_by_patient_id[patient.id].reject(&:patient_had_valid_care_plan?)&.size
    end

    def acos_for_patient(patient)
      patient.patient_referrals.select { |r| r.active_within?(report_date_range) }.map { |r| r.aco&.name }.compact.uniq
    end

    def qualifying_activities_by_patient_id
      @qualifying_activities_by_patient_id ||= ::Health::QualifyingActivity.where(
        patient: active_patients,
      ).submitted.in_range(
        report_date_range,
      ).group_by(&:patient_id)
    end

    def patients_without_payments
      active_patients.where.not(
        medicaid_id: payment_details.select(:medicaid_id),
      ).preload(:careplans, patient_referrals: :aco)
    end

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

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << ['Medicaid ID', 'First Name', 'Last Name', 'Care Plans Signed', 'Qualifying Activities']
        patients_without_payments.each do |patient|
          csv << [
            patient.medicaid_id,
            patient.first_name,
            patient.last_name,
            patient.careplans.map { |d| l d.provider_signed_on }.to_sentence,
            qualifying_activities_by_patient_id(patient)&.size,
          ]
        end
      end
    end
  end
end
