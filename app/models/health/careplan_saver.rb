# A wrapper around careplan changes to ease Qualifying Activities creation
module Health
  class CareplanSaver

    def initialize user:, careplan: Health::Careplan.new
      @user = user
      @careplan = careplan
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      @careplan.class.transaction do
        @careplan.save!
        @careplan.import_team_members
      end
    end


    def update
      @careplan.class.transaction do
        if @careplan.just_signed?
          @qualifying_activity.activity = 'Person-Centered Treatment Plan signed'
        end
        @careplan.save!
        @qualifying_activity.source_id = @careplan.id
        @qualifying_activity.save
        @careplan.set_lock
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @careplan.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.today,
        activity: 'Care planning',
        follow_up: 'Implement Person-Centered Treatment Planning',
        reached_client: 'Yes (face to face, phone call answered, response to email)',
        mode_of_contact: 'In Person',
        patient_id: @careplan.patient_id
      )
    end

  end
end