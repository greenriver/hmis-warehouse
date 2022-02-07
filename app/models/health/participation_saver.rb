###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A wrapper around Participation form changes to ease Qualifying Activities creation
module Health
  class ParticipationSaver

    def initialize user:, form: Health::ParticipationForm.new, create_qa: false
      @user = user
      @form = form
      @create_qa = create_qa
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      update
    end

    def update
      success = true
      begin
        @form.class.transaction do
          include_qualifying_activity = @form.signature_on.present? && @form.signature_on_changed?
          @form.save!
          if include_qualifying_activity && @create_qa
            @qualifying_activity.source_id = @form.id
            @qualifying_activity.save
          end
        end
      rescue Exception => e
        success = false
      end
      return success
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @form.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.current,
        activity: :outreach,
        follow_up: 'Engage Patient',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @form.patient_id
      )
    end


  end
end
