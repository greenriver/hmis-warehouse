###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A wrapper around careplan changes to ease Qualifying Activities creation
module Health
  class CareplanSaver
    def initialize user:, careplan: Health::Careplan.new, create_qa: false
      @user = user
      @careplan = careplan
      @create_qa = create_qa
    end

    def create
      @careplan.class.transaction do
        @careplan.save!
        @careplan.import_team_members
      end
    end

    def update
      success = true
      @careplan.compact_future_issues

      begin
        @careplan.class.transaction do
          # This needs to be done before the save so that the _changed tracking is triggered
          care_planning_qa = setup_care_planning_qualifying_activity if @careplan.just_finished? && @create_qa
          cha_approved_qa = setup_cha_approved_qualifying_activity if @careplan.ncm_just_approved? && @create_qa
          sdoh_qa = setup_sdoh_qualifying_activity if @careplan.ncm_just_approved? && @create_qa
          pctp_signed_qa = setup_pctp_signed_qualifying_activity if @careplan.rn_just_approved? && @create_qa

          # Validate the save so that no QAs are  created if the PCTP is invalid
          @careplan.save!

          # This is done after the save to guarantee the careplan has an id
          complete_qa(care_planning_qa) if care_planning_qa.present?
          save_qa(cha_approved_qa) if cha_approved_qa.present?
          save_qa(sdoh_qa) if sdoh_qa.present?
          complete_qa(pctp_signed_qa) if pctp_signed_qa.present?

          @careplan.set_lock
        end
      rescue Exception
        success = false
      end
      return success
    end

    private def complete_qa(qualifying_activity)
      qualifying_activity.source_id = @careplan.id
      save_qa(qualifying_activity)
    end

    private def save_qa(qualifying_activity)
      qualifying_activity.save!
      qualifying_activity.maintain_cached_values
    end

    private def setup_care_planning_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @careplan.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        activity: :care_planning,
        date_of_activity: @careplan.patient_signed_on,
        mode_of_contact: :in_person,
        reached_client: :yes,
        follow_up: 'This writer completed Care Plan with patient. Patient agreed to care plan.',
        patient_id: @careplan.patient_id,
      )
    end

    private def setup_pctp_signed_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @careplan.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        activity: :pctp_signed,
        date_of_activity: [@careplan.rn_approved_on, '2023-04-01'.to_date].max,
        mode_of_contact: nil, # There are no contact modifiers listed in the QA specification
        reached_client: nil,
        follow_up: 'Approve Person-Centered Treatment Plan',
        patient_id: @careplan.patient_id,
      )
    end

    private def setup_cha_approved_qualifying_activity
      @cha = @careplan.patient.recent_cha_form

      Health::QualifyingActivity.new(
        source_type: @cha.class.name,
        source_id: @cha.id,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        activity: :cha_completed,
        date_of_activity: [@careplan.ncm_approved_on, '2023-04-01'.to_date].max,
        mode_of_contact: nil, # There are no contact modifiers listed in the QA specification
        reached_client: nil,
        follow_up: 'Approve Comprehensive Assessment',
        patient_id: @careplan.patient_id,
      )
    end

    private def setup_sdoh_qualifying_activity
      @ssm = @careplan.patient.recent_ssm_form
      return unless @ssm.present?

      qa = Health::QualifyingActivity.new(
        source_type: @ssm.class.name,
        source_id: @ssm.id,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: [@careplan.ncm_approved_on, '2023-04-01'.to_date].max,
        mode_of_contact: nil, # There are no contact modifiers listed in the QA specification
        reached_client: nil,
        patient_id: @careplan.patient_id,
      )
      if @ssm.positive_sdoh?
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

      qa
    end
  end
end
