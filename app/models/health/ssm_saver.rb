###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A wrapper around SSM form changes to ease Qualifying Activities creation
module Health
  class SsmSaver

    def initialize user:, ssm:, create_qa: false
      @user = user
      @ssm = ssm
      @create_qa = create_qa
    end

    def create
      @ssm.class.transaction do
        @ssm.save(validate: false)
      end
    end

    def update
      @ssm.class.transaction do
        if @ssm.completed_at.present? && @ssm.completed_at_changed? && @create_qa
          @qualifying_activity = Health::QualifyingActivity.where(
            source_id: @ssm.id,
            source_type: @ssm.class.name,
          ).first_or_initialize
          @qualifying_activity.assign_attributes(
            user_id: @user.id,
            user_full_name: @user.name_with_email,
            date_of_activity: @ssm.completed_at,
            activity: :cha,
            follow_up: 'Improve Patient Outcomes',
            reached_client: :yes,
            mode_of_contact: :in_person,
            patient_id: @ssm.patient_id
          )
        end
        @ssm.save!
      end
    end
  end
end
