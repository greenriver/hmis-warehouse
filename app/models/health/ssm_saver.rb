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
          @cha = @ssm.patient.recent_cha_form
          if @cha.completed? && @cha.reviewed?
            qualifying_activity = setup_qualifying_activity
            qualifying_activity.save
          end
        end
        @ssm.save!
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @cha.class.name,
        source_id: @cha.id,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: @cha.completed_at.date,
        activity: :cha,
        follow_up: 'This writer completed CHA and SSM with patient.',
        reached_client: :yes,
        mode_of_contact: @cha.collection_method,
        patient_id: @cha.patient_id,
      )
    end
  end
end
