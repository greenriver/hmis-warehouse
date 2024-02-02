###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A wrapper around CHA changes to ease Qualifying Activities creation
module Health
  class ChaSaver
    def initialize user:, cha: Health::ComprehensiveHealthAssessment.new, complete: false, reviewed: false, create_qa: false
      @user = user
      @cha = cha
      @complete = complete
      @reviewed = reviewed
      @create_qa = create_qa

      @cha.completed_at = Time.current if @complete
      @cha.reviewed_by = @user if @reviewed
      # if they check the checkbox
      # and then uncheck before hitting save button
      # some of these values were sticking around
      # clear everything
      @cha.reviewed_by = nil unless @reviewed
      @cha.reviewed_at = nil unless @reviewed
      @cha.reviewer = nil unless @reviewed
      # fall back to reviewer being reviewed_by if they don't provide a name
      @cha.reviewer = @cha.reviewed_by.name if @reviewed && !@cha.reviewer.present?
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
        # The CHA QA actually requires both the CHA and the SSM, so check both
        # also done in the SsmSaver so it can be done in either order
        if @complete && @create_qa && @cha.patient.recent_ssm_form&.completed_at.present?
          qualifying_activity = if @reviewed
            setup_completed_qualifying_activity
          else
            setup_development_qualifying_activity
          end
          qualifying_activity.save
          qualifying_activity.maintain_cached_values
        end
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
        date_of_activity: @cha.reviewed_at.to_date,
        activity: :cha_completed,
        follow_up: 'CHA and SSM for patient approved by NCM.',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @cha.patient_id,
      )
    end
  end
end
