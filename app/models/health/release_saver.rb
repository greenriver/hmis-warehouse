# A wrapper around Participation form changes to ease Qualifying Activities creation
module Health
  class ReleaseSaver

    def initialize user:, form: Health::ReleaseForm.new
      @user = user
      @form = form
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      update
    end

    def update
      @form.class.transaction do
        include_qualifying_activity = @form.signature_on.present? && @form.signature_on_changed?
        @form.save
        if include_qualifying_activity
          @qualifying_activity.source_id = @form.id
          @qualifying_activity.save
        end
      end
      return true
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @form.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.today,
        activity: :outreach,
        follow_up: 'Engage Patient',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @form.patient_id
      )
    end


  end
end