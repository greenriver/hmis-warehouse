###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
          # The CHA QA requires both the CHA and the SSM, so check both
          # also done in the ChaSaver so it can be done in either order
          @cha = @ssm.patient.recent_cha_form
          if @cha.present? && @cha.completed?
            qualifying_activity = if @cha.reviewed?
              setup_completed_qualifying_activity
            else
              setup_development_qualifying_activity
            end
            qualifying_activity.save
            qualifying_activity.maintain_cached_values
          end
        end
        @ssm.save!
      end
    end

    private def setup_development_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @cha.class.name,
        source_id: @cha.id,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: @cha.completed_at.to_date,
        activity: :cha,
        follow_up: 'This writer completed CHA and SSM with patient.',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @cha.patient_id,
      )
    end

    private def setup_completed_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @cha.class.name,
        source_id: @cha.id,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: @cha.completed_at.to_date,
        activity: :cha_completed,
        follow_up: 'CHA and SSM for patient approved by NCM.',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @cha.patient_id,
      )
    end
  end
end
