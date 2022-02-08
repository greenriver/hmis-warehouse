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
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      @careplan.class.transaction do
        @careplan.save!
        @careplan.import_team_members
      end
    end


    def update
      success = true
      # limited to only signatures 11/27 per request from BHCHP, only save QA for signatures
      should_really_create_qa = @careplan.just_signed? && @create_qa
      @careplan.compact_future_issues
      begin
        @careplan.class.transaction do
          if should_really_create_qa
            signature_date = @careplan.provider_signed_on
            @qualifying_activity.date_of_activity = signature_date

            case @careplan.provider_signature_mode.to_s
            when 'email'
              @qualifying_activity.mode_of_contact = :other
              @qualifying_activity.reached_client = :collateral
              @qualifying_activity.mode_of_contact_other = 'On-line'
              @qualifying_activity.reached_client_collateral_contact = 'On-line Signature'
            when 'in_person'
              @qualifying_activity.mode_of_contact = :in_person
              @qualifying_activity.reached_client = :yes
            else
              # default to email signature
              @qualifying_activity.mode_of_contact = :other
              @qualifying_activity.reached_client = :collateral
              @qualifying_activity.mode_of_contact_other = 'On-line'
              @qualifying_activity.reached_client_collateral_contact = 'On-line Signature'
            end
          end

          @careplan.save

          if should_really_create_qa
            @qualifying_activity.source_id = @careplan.id

            @qualifying_activity.save
          end
          @careplan.set_lock
        end
      rescue Exception => e
        success = false
      end
      return success
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @careplan.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        activity: :pctp_signed,
        follow_up: 'Implement Person-Centered Treatment Planning',
        patient_id: @careplan.patient_id,
      )
    end
  end
end
