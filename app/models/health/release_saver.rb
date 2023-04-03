###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A wrapper around Participation form changes to ease Qualifying Activities creation
module Health
  class ReleaseSaver
    def initialize user:, form: Health::ReleaseForm.new, create_qa: false
      @user = user
      @form = form
      @create_qa = create_qa
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      update
    end

    def update
      @form.class.transaction do
        # If the form is completely signed, and was not previously, a QA can be generated
        include_qualifying_activity = @form.signature_on.present? && @form.participation_signature_on.present? &&
          (@form.signature_on_was.blank? || @form.participation_signature_on_was.blank?)
        @form.save
        if include_qualifying_activity && @create_qa
          @qualifying_activity.source_id = @form.id
          @qualifying_activity.save
          @qualifying_activity.maintain_cached_values
        end
      end
      return true
    end

    protected def setup_qualifying_activity
      mode_of_contact = @form.mode_of_contact
      follow_up_text = if mode_of_contact == :in_person
        'Patient agreed to participation form and ROI.'
      else
        'Due to COVID-19, this writer received directed signature for the consent to the CP program and directed signature for ROI (uploaded to HMIS).'
      end
      Health::QualifyingActivity.new(
        source_type: @form.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: [@form.signature_on, @form.participation_signature_on].max,
        activity: :outreach,
        follow_up: follow_up_text,
        reached_client: :yes,
        mode_of_contact: mode_of_contact,
        patient_id: @form.patient_id,
      )
    end
  end
end
