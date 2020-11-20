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
        scope = scope.merge(
          ::Health::PatientReferral.where(
            accountable_care_organization_id: aco_ids,
          ),
        )
      end
      scope
    end

    def qualifying_activity_count_for_patient(patient)
      qualifying_activity_counts_by_patient_id[patient.id]
    end

    def acos_for_patient(patient)
      patient.patient_referrals.select { |r| r.active_within?(report_date_range) }.map { |r| r.aco&.name }.compact.uniq
    end

    def qualifying_activity_counts_by_patient_id
      @qualifying_activity_counts_by_patient_id ||= ::Health::QualifyingActivity.where(
        patient: active_patients,
      ).submitted.in_range(
        report_date_range,
      ).group(:patient_id).count
    end

    def patients_without_payments
      active_patients.where.not(
        medicaid_id: payment_details.select(:medicaid_id),
      ).preload(patient_referrals: :aco)
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
  end
end
