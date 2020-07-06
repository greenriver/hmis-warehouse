###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class AcoPerformance
    include ArelHelper

    attr_accessor :range
    def initialize(aco:, range:)
      @aco = aco
      @range = (range.first.to_date..range.last.to_date)
    end

    def patient_referrals
      @patient_referrals ||= referral_scope.
        pluck(:patient_id, hpr_t[:enrollment_start_date]).
        to_h
    end

    def patients
      Health::Patient.where(id: patient_referrals.keys).order(:last_name, :first_name)
    end

    def qa_signature_dates
      # Note: using minimum will ensure the first PCTP, subsequent don't matter
      @qa_signatures ||= Health::QualifyingActivity.submittable.
        during_current_enrollment.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
      where(date_of_activity: @range).
        where(activity: :pctp_signed).
        group(:patient_id).minimum(:date_of_activity)
    end

   def with_careplans_in_122_days
      @with_careplans_in_122_days ||= patient_referrals.keys.map do |p_id|
        careplan_date = qa_signature_dates[p_id]&.to_date
        enrollment_date = patient_referrals[p_id]&.to_date

        signed = careplan_date.present? &&
          enrollment_date.present? &&
          careplan_date.between?(@range.first, @range.last) &&
          (careplan_date - enrollment_date).to_i <= 122

        [p_id, signed]
      end.to_h
    end

    private def referral_scope
      Health::PatientReferral.
        with_patient.
        where(accountable_care_organization_id: @aco).
        active_within_range(start_date: @range.first, end_date: @range.last)
    end
  end
end
