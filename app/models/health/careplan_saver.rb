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
      just_signed = @careplan.just_signed?
      begin
        @careplan.class.transaction do          
          if just_signed && @create_qa
            just_signed = true
            @qualifying_activity.activity = :pctp_signed
          end
          @careplan.save!
          # limited to only signatures 11/27 per request from BHCHP, only save QA for signatures
          if just_signed && @create_qa
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
        date_of_activity: Date.today,
        activity: :care_planning,
        follow_up: 'Implement Person-Centered Treatment Planning',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @careplan.patient_id
      )
    end

  end
end