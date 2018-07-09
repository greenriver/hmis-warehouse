# A wrapper around CHA changes to ease Qualifying Activities creation
module Health
  class ChaSaver

    def initialize user:, cha: Health::ComprehensiveHealthAssessment.new, complete: false, reviewed: false
      @user = user
      @cha = cha
      @complete = complete
      @reviewed = reviewed
      @qualifying_activity = setup_qualifying_activity

      @cha.completed_at = Time.current if @complete
      @cha.reviewed_by = @user if @reviewed
    end

    def create
      @cha.class.transaction do
        @cha.save(validate: false)
      end
    end


    def update
      @cha.class.transaction do
        @cha.completed_at = nil unless @complete
        @cha.save!
        if @complete || @reviewed
          @qualifying_activity.source_id = @cha.id
          @qualifying_activity.save
        end
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @cha.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.today,
        activity: :cha,
        follow_up: 'Implement Comprehensive Health Assessment',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @cha.patient_id
      )
    end

  end
end