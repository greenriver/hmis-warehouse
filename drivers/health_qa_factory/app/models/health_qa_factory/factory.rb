###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthQaFactory
  class Factory < HealthBase
    belongs_to :patient, class_name: 'Health::Patient'
    belongs_to :careplan, class_name: 'HealthPctp::Careplan', optional: true

    belongs_to :hrsn_screening_qa, class_name: 'Health::QualifyingActivity', optional: true
    belongs_to :ca_development_qa, class_name: 'Health::QualifyingActivity', optional: true
    belongs_to :ca_completed_qa, class_name: 'Health::QualifyingActivity', optional: true
    belongs_to :careplan_development_qa, class_name: 'Health::QualifyingActivity', optional: true
    belongs_to :careplan_completed_qa, class_name: 'Health::QualifyingActivity', optional: true

    def complete?
      careplan_completed_qa.present?
    end

    def complete_hrsn(screener)
      # HRSN QAs are delayed until careplan approval
    end

    def complete_ca(assessment)
      update(ca_development_qa: create_ca_development_qa(assessment)) unless ca_development_qa.present?
    end

    def complete_careplan(careplan)
      update(careplan_development_qa: create_careplan_development_qa(careplan)) unless careplan_development_qa.present?
    end

    def review_careplan(careplan)
      update(careplan: careplan)
      update(hrsn_screening_qa: create_hrsn_screening_qa(patient.recent_hrsn_screening&.instrument)) unless hrsn_screening_qa.present?
      return if ca_completed_qa.present?

      ca = patient.recent_ca_assessment&.instrument
      ca.update(reviewed_on: careplan.reviewed_by_ccm_on, reviewed_by_id: careplan.reviewed_by_ccm_id)
      update(ca_completed_qa: create_ca_completed_qa(ca))
    end

    def approve_careplan(careplan)
      update(careplan_completed_qa: create_careplan_completed_qa(careplan)) unless careplan_completed_qa.present?
    end

    private def create_hrsn_screening_qa(screener)
      return unless screener.present?

      user = User.find(careplan.reviewed_by_ccm_id)

      qa = ::Health::QualifyingActivity.new(
        source_type: screener.class.name,
        source_id: screener.id,
        user_id: user.id,
        user_full_name: user.name_with_email,
        date_of_activity: careplan.reviewed_by_ccm_on,
        mode_of_contact: nil, # There are no contact modifiers listed in the QA specification
        reached_client: nil,
        patient_id: careplan.patient_id,
      )
      if screener.positive_sdoh?
        qa.assign_attributes(
          activity: :sdoh_positive,
          follow_up: 'Patient SDoH Screening Positive',
        )
      else
        qa.assign_attributes(
          activity: :sdoh_negative,
          follow_up: 'Patient SDoH Screening Negative',
        )
      end
      qa.save

      qa
    end

    private def create_ca_development_qa(assessment)
      return unless assessment.present?

      user = User.find(assessment.user_id)

      ::Health::QualifyingActivity.create(
        source_type: assessment.class.name,
        source_id: assessment.id,
        user_id: assessment.id,
        user_full_name: user.name_with_email,
        date_of_activity: assessment.completed_on,
        activity: :cha,
        follow_up: 'This writer completed CHA and SSM with patient.',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: assessment.patient_id,
      )
    end

    private def create_ca_completed_qa(assessment)
      return unless assessment.present?

      user = User.find(careplan.reviewed_by_ccm_id)

      ::Health::QualifyingActivity.create(
        source_type: assessment.class.name,
        source_id: assessment.id,
        user_id: user.id,
        user_full_name: user.name_with_email,
        activity: :cha_completed,
        date_of_activity: careplan.reviewed_by_ccm_on,
        mode_of_contact: nil, # There are no contact modifiers listed in the QA specification
        reached_client: nil,
        follow_up: 'Approve Comprehensive Assessment',
        patient_id: assessment.patient_id,
      )
    end

    private def create_careplan_development_qa(careplan)
      return unless careplan.present?

      user = User.find(careplan.user_id)

      ::Health::QualifyingActivity.create(
        source_type: careplan.class.name,
        source_id: careplan.id,
        user_id: user.id,
        user_full_name: user.name_with_email,
        activity: :care_planning,
        date_of_activity: careplan.patient_signed_on,
        mode_of_contact: :in_person,
        reached_client: :yes,
        follow_up: 'This writer completed Care Plan with patient. Patient agreed to care plan.',
        patient_id: careplan.patient_id,
      )
    end

    private def create_careplan_completed_qa(careplan)
      return unless careplan.present?

      user = User.find(careplan.reviewed_by_rn_id)

      ::Health::QualifyingActivity.create(
        source_type: careplan.class.name,
        source_id: careplan.id,
        user_id: user.id,
        user_full_name: user.name_with_email,
        activity: :pctp_signed,
        date_of_activity: careplan.reviewed_by_rn_on,
        mode_of_contact: nil, # There are no contact modifiers listed in the QA specification
        reached_client: nil,
        follow_up: 'Approve Person-Centered Treatment Plan',
        patient_id: careplan.patient_id,
      )
    end
  end
end
