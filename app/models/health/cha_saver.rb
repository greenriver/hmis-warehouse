###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      @qualifying_activity = setup_qualifying_activity

      @cha.completed_at = Time.current if @complete
      @cha.reviewed_by = @user if @reviewed
      # if they check the checkbox
      # and then uncheck before hitting save button
      # some of these values were sticking around
      # clear everything
      @cha.reviewed_by = nil if !@reviewed
      @cha.reviewed_at = nil if !@reviewed
      @cha.reviewer = nil if !@reviewed
      # fall back to reviewer being reviewed_by if they don't provide a name
      if @reviewed && !@cha.reviewer.present?
        @cha.reviewer = @cha.reviewed_by.name
      end
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
        if @complete && @reviewed && @create_qa
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
        date_of_activity: Date.current,
        activity: :cha,
        follow_up: 'Implement Comprehensive Health Assessment',
        reached_client: :yes,
        mode_of_contact: :in_person,
        patient_id: @cha.patient_id
      )
    end

  end
end
