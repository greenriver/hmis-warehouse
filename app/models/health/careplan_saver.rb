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

      # limited to only signatures 11/27 per request from BHCHP, only save QA for signatures
      begin
        @careplan.class.transaction do
          if @careplan.just_finished? && @create_qa
            qualifying_activity = setup_care_planning_qualifying_activity
          elsif @careplan.just_signed? && @create_qa
            qualifying_activity = setup_pctp_signed_qualifying_activity
          end

          @careplan.save!

          if qualifying_activity.present?
            qualifying_activity.source_id = @careplan.id

            qualifying_activity.save
          end
          @careplan.set_lock
        end
      rescue Exception
        success = false
      end
      return success
    end

    protected def setup_care_planning_qualifying_activity
      if @careplan.member_verbalizes_understanding?
        mode_of_contact = :phone
        text = 'This writer completed Care Plan with patient. Patient gave verbal approval to Care Plan due to COVID-19.'
      else
        mode_of_contact = :in_person
        text = 'This writer completed Care Plan with patient. Patient agreed to care plan.'
      end

      Health::QualifyingActivity.new(
        source_type: @careplan.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        activity: :care_planning,
        date_of_activity: @careplan.patient_signed_on,
        mode_of_contact: mode_of_contact,
        reached_client: :yes,
        follow_up: text,
        patient_id: @careplan.patient_id,
      )
    end

    protected def setup_pctp_signed_qualifying_activity
      case @careplan.provider_signature_mode.to_s
      when 'email'
        mode_of_contact = :other
        reached_client = :collateral
        mode_of_contact_other = 'On-line'
        reached_client_collateral_contact = 'On-line Signature'
      when 'in_person'
        mode_of_contact = :in_person
        reached_client = :yes
        mode_of_contact_other = nil
        reached_client_collateral_contact = nil
      else
        # default to email signature
        mode_of_contact = :other
        reached_client = :collateral
        mode_of_contact_other = 'On-line'
        reached_client_collateral_contact = 'On-line Signature'
      end

      Health::QualifyingActivity.new(
        source_type: @careplan.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        activity: :pctp_signed,
        date_of_activity: @careplan.provider_signed_on,
        mode_of_contact: mode_of_contact,
        mode_of_contact_other: mode_of_contact_other,
        reached_client: reached_client,
        reached_client_collateral_contact: reached_client_collateral_contact,
        follow_up: 'Implement Person-Centered Treatment Planning',
        patient_id: @careplan.patient_id,
      )
    end
  end
end
