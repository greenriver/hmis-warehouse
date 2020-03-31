###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::CareplanDates # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern
  included do
    private def care_plan_patient_signed_date(patient_id)
      @care_plan_patient_signed_dates ||= Health::Careplan.after_enrollment_date.where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:patient_signed_on)
      @care_plan_patient_signed_dates[patient_id]&.to_date
    end

    private def care_plan_sent_to_provider_date(patient_id)
      @care_plan_sent_to_provider_dates ||= begin
        signature_request_dates = Health::Careplan.after_enrollment_date.where(patient_id: patient_ids).
          group(:patient_id).
          maximum(:provider_signature_requested_at)

        signature_request_dates.each do |id, date|
          signature_request_dates[id] = care_plan_provider_signed_date(id) if date.blank?
        end
        signature_request_dates
      end

      @care_plan_sent_to_provider_dates[patient_id]&.to_date
    end

    private def care_plan_provider_signed_date(patient_id)
      @care_plan_provider_signed_dates ||= Health::Careplan.after_enrollment_date.where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:provider_signed_on)
      @care_plan_provider_signed_dates[patient_id]&.to_date
    end

    private def qa_signature_dates
      @qa_signature_dates ||= Health::QualifyingActivity.submittable.
        after_enrollment_date.
        where(patient_id: patient_ids).
        where(activity: :pctp_signed).
        group(:patient_id).minimum(:date_of_activity)
    end

    private def with_careplans_in_122_days?(patient, as: :boolean) # rubocop:disable Naming/MethodParameterName
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
