###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class AcoPerformance
    include ArelHelper

    attr_accessor :range
    def initialize(aco)
      @aco = aco
    end

    def patient_referrals
      @patient_referrals ||= referral_scope.group(:patient_id).minimum(:enrollment_start_date)
    end

    def patients
      Health::Patient.where(id: patient_referrals.keys).order(:last_name, :first_name)
    end

    def qa_signature_dates
      @qa_signatures ||= Health::QualifyingActivity.submittable.
        # during_current_enrollment. # Any PCTP signature counts as a signed care plan
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        where(activity: :pctp_signed).
        group(:patient_id).maximum(:date_of_activity) # Most recent signed care plan
    end

   def with_careplans_in_122_days_status
      @with_careplans_in_122_days_status ||= patient_referrals.keys.map do |p_id|
        careplan_date = qa_signature_dates[p_id]&.to_date
        enrollment_date = patient_referrals[p_id]&.to_date

        signed = careplan_date.present? &&
          enrollment_date.present? &&
          careplan_date >= enrollment_date &&
          # careplan_date.between?(@range.first, @range.last) && # Any PCTP signature counts as a signed care plan
          (careplan_date - enrollment_date).to_i <= 122

        [p_id, signed]
      end.to_h
    end

    private def referral_scope
      Health::PatientReferral.
        contributing.
        at_acos(@aco)
    end
  end
end
