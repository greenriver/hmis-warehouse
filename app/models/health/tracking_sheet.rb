###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class TrackingSheet
    include ArelHelper

    def initialize patients
      @patient_ids = patients.map(&:id)
    end

    def consented_date patient_id
      @consented_dates ||= Health::ParticipationForm.where(patient_id: @patient_ids).
        group(:patient_id).
        maximum(:signature_on)
      @consented_dates[patient_id]&.to_date
    end

    def ssm_completed_date patient_id
      @ssm_completed_dates ||= Health::SelfSufficiencyMatrixForm.where(patient_id: @patient_ids).
        group(:patient_id).
        maximum(:completed_at)
      @ssm_completed_dates[patient_id]&.to_date
    end

    def cha_completed_date patient_id
      @cha_completed_dates ||= Health::ComprehensiveHealthAssessment.where(patient_id: @patient_ids).
        group(:patient_id).
        maximum(:completed_at)
      @cha_completed_dates[patient_id]&.to_date
    end

    def cha_reviewed_date patient_id
      @cha_reviewed_dates ||= Health::ComprehensiveHealthAssessment.where(patient_id: @patient_ids).
        group(:patient_id).
        maximum(:reviewed_at)
      @cha_reviewed_dates[patient_id]&.to_date
    end

    def care_plan_patient_signed_date patient_id
      @care_plan_patient_signed_dates ||= Health::Careplan.where(patient_id: @patient_ids).
        group(:patient_id).
        maximum(:patient_signed_on)
      @care_plan_patient_signed_dates[patient_id]&.to_date
    end

    def care_plan_provider_signed_date patient_id
      @care_plan_provider_signed_dates ||= Health::Careplan.where(patient_id: @patient_ids).
        group(:patient_id).
        maximum(:provider_signed_on)
      @care_plan_provider_signed_dates[patient_id]&.to_date
    end

    def most_recent_face_to_face_qa_date patient_id
      @most_recent_face_to_face_qa_dates ||= Health::QualifyingActivity.direct_contact.face_to_face.
        where(patient_id: @patient_ids).
        group(:patient_id).
        maximum(:date_of_activity)
      @most_recent_face_to_face_qa_dates[patient_id]&.to_date
    end

    # def most_recent_qa_from_case_management_note patient_id
    #   @most_recent_qa_from_case_management_notes ||= Health::SdhCaseManagementNote.
    #     joins(:activities).
    #     where(patient_id: @patient_ids).
    #     group(:patient_id).
    #     maximum(:date_of_contact)
    #   @most_recent_qa_from_case_management_notes[patient_id]&.to_date
    # end

    # def most_recent_qa_from_eto_case_note patient_id
    #   @eto_form_ids ||= GrdaWarehouse::HmisForm.has_qualifying_activities.pluck(:id)
    #   @most_recent_qa_from_eto_case_notes ||= Health::QualifyingActivity.
    #     where(source_type: 'GrdaWarehouse::HmisForm', source_id: @eto_form_ids).
    #     where(patient_id: @patient_ids).
    #     group(:patient_id).
    #     maximum(:date_of_activity)
    #   @most_recent_qa_from_eto_case_notes[patient_id]&.to_date
    # end

    # def most_recent_qa_from_epic_case_management_note patient_id
    #   @most_recent_qa_from_epic_case_management_notes ||= Health::EpicCaseNoteQualifyingActivity.
    #     joins(:patient).
    #     merge(Health::Patient.where(id: @patient_ids)).
    #     group(:patient_id).
    #     maximum(:update_date)
    #   @most_recent_qa_from_epic_case_management_notes[patient_id]&.to_date
    # end

    def most_recent_qa_from_case_note patient_id
      @most_recent_qa_from_case_note ||= Health::QualifyingActivity.
        where(
          source_type: [
            "GrdaWarehouse::HmisForm",
            "Health::SdhCaseManagementNote",
            "Health::EpicQualifyingActivity",
          ]
        ).
        joins(:patient).
        merge(Health::Patient.where(id: @patient_ids)).
        group(:patient_id).
        maximum(:date_of_activity)
      @most_recent_qa_from_case_note[patient_id]
    end

    def cha_renewal_date patient_id
      reviwed_date = cha_reviewed_date(patient_id)
      return nil unless reviwed_date.present?
      reviwed_date + 1.years
    end

    def care_plan_renewal_date patient_id
      signed_date = care_plan_provider_signed_date(patient_id)
      return nil unless signed_date.present?
      signed_date + 1.years
    end

    def aco_name patient_id
      @aco_names ||= Health::AccountableCareOrganization.joins(patient_referrals: :patient).
        merge(Health::Patient.where(id: @patient_ids)).
        pluck(hp_t[:id].to_sql, :name).to_h
      @aco_names[patient_id]
    end

    def care_coordinator patient_id
      @patient_coordinator_lookup ||= Health::Patient.pluck(:id, :care_coordinator_id).to_h
      @care_coordinators ||= User.where(id: @patient_coordinator_lookup.values).
        distinct.map{ |m| [m.id, m.name] }.to_h

      @care_coordinators[@patient_coordinator_lookup[patient_id]]
    end

    def row patient
      {
        'ID_MEDICAID' => patient.medicaid_id,
        'NAM_FIRST' => patient.first_name,
        'NAM_LAST' => patient.last_name,
        'DTE_BIRTH' => patient.birthdate,
        'ACO_NAME' => aco_name(patient.id),
        'CARE_COORDINATOR' => care_coordinator(patient.id),
        'ASSIGNMENT_DATE' => patient.enrollment_start_date,
        'CONSENT_DATE' => consented_date(patient.id),
        # Limit SSM and CHA to warehouse versions only (per spec)
        'SSM_DATE' => ssm_completed_date(patient.id),
        'CHA_DATE' => cha_completed_date(patient.id),
        'CHA_REVIEWED' => if cha_reviewed_date(patient.id).present? then 'Yes' else 'No' end,
        'CHA_RENEWAL_DATE' => cha_renewal_date(patient.id),
        'PCTP_PT_SIGN' => care_plan_patient_signed_date(patient.id),
        'PCTP_PCP_SIGN' => care_plan_provider_signed_date(patient.id),
        'PCTP_RENEWAL_DATE' => care_plan_renewal_date(patient.id),
        'QA_FACE_TO_FACE' => most_recent_face_to_face_qa_date(patient.id),
        'QA_LAST' => most_recent_qa_from_case_note(patient.id),
      }
    end
  end
end