# A wrapper around SSM form changes to ease Qualifying Activities creation
module Health
  class SsmSaver

    def initialize user:, ssm: Health::SelfSufficiencyMatrixForm.new, complete: false
      @user = user
      @ssm = ssm
      @complete = complete
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      @ssm.class.transaction do
        @ssm.save(validate: false)
      end
    end

    def update
      @ssm.class.transaction do 
        @ssm.completed_at = Time.current if @complete
        @ssm.save!
        @qualifying_activity.source_id = @ssm.id
        @qualifying_activity.save
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @ssm.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.today,
        activity: 'Comprehensive Health Assessment',
        follow_up: 'Improve Patient Outcomes',
        reached_client: 'Yes (face to face, phone call answered, response to email)',
        mode_of_contact: 'In Person',
        patient_id: @ssm.patient_id
      )
    end


  end
end