# A wrapper around CHA changes to ease Qualifying Activities creation
module Health
  class ChaSaver

    def initialize user:, cha: Health::ComprehensiveHealthAssessment.new
      @user = user
      @cha = cha
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      @cha.class.transaction do
        @cha.save!
      end
    end


    def update
      @cha.class.transaction do
        if @cha.just_signed?
          @qualifying_activity.activity = 'Person-Centered Treatment Plan signed'
        end
        @cha.save!
        @qualifying_activity.source_id = @cha.id
        @qualifying_activity.save
        @cha.set_lock
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @cha.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.today,
        activity: 'Comprehensive Health Assessment',
        follow_up: 'Implement Comprehensive Health Assessment',
        reached_client: 'Yes (face to face, phone call answered, response to email)',
        mode_of_contact: 'In Person',
        patient_id: @cha.patient_id
      )
    end
    
  end
end