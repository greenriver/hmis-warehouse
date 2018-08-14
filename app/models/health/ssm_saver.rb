# A wrapper around SSM form changes to ease Qualifying Activities creation
module Health
  class SsmSaver

    def initialize user:, ssm: Health::SelfSufficiencyMatrixForm.new
      @user = user
      @ssm = ssm
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      @ssm.class.transaction do
        @ssm.save(validate: false)
      end
    end

    def update
      @ssm.class.transaction do
        if @ssm.completed_at_changed? && @ssm.completed_at_was == nil
          @qualifying_activity.source_id = @ssm.id
          @qualifying_activity.save
        end
        @ssm.save!
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @ssm.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.today,
        activity: :cha,
        follow_up: 'Improve Patient Outcomes',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @ssm.patient_id
      )
    end


  end
end