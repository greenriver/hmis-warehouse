###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::CareplanDates
  extend ActiveSupport::Concern
  included do
    private def care_plan_patient_signed_date(patient_id)
      @care_plan_patient_signed_dates ||= Health::Careplan.where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:patient_signed_on)
      @care_plan_patient_signed_dates[patient_id]&.to_date
    end

    private def care_plan_sent_to_provider_date(patient_id)
      careplans = Health::Careplan.where(patient_id: patient_id).
        order(Arel.sql(h_cp_t[:provider_signed_on].desc.to_sql + ' NULLS LAST'),
              Arel.sql(h_cp_t[:provider_signature_requested_at].desc.to_sql + ' NULLS LAST'))
      return unless careplans.exists?

      # Return the request date if the most recent careplan is signed, or is the only careplan
      careplan = careplans.first
      # If there is no request date, use the signature data as the request date
      requested_date = careplan.provider_signature_requested_at&.to_date || careplan.provider_signed_on&.to_date
      return requested_date if careplan.provider_signed_on || careplans.count == 1

      # Otherwise use the next most recent careplan w/ a signature or request
      careplan = careplans.drop(1).select { |cp| cp.provider_signed_on.present? || cp.provider_signature_requested_at.present? }.first
      return unless careplan.present?

      careplan.provider_signature_requested_at&.to_date || careplan.provider_signed_on&.to_date
    end

    private def care_plan_provider_signed_date(patient_id)
      @care_plan_provider_signed_dates ||= Health::Careplan.where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:provider_signed_on)
      @care_plan_provider_signed_dates[patient_id]&.to_date
    end

    private def qa_signature_dates
      @qa_signature_dates ||= Health::QualifyingActivity.submittable.
        during_current_enrollment.
        where(patient_id: patient_ids).
        where(activity: :pctp_signed).
        group(:patient_id).minimum(:date_of_activity)
    end

    private def with_careplans_in_122_days?(patient, as: :boolean)
      signature_date = qa_signature_dates[patient.id]
      return nil unless signature_date
      return nil unless patient.enrollment_start_date

      boolean = (signature_date - patient.enrollment_start_date).to_i <= 122
      case as
      when :boolean
        boolean
      when :text
        if boolean then 'Y' else 'N' end
      end
    end
  end
end
