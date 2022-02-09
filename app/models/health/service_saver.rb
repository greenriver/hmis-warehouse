###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A wrapper around Services form changes to ease Qualifying Activities creation
module Health
  class ServiceSaver

    def initialize user:, service: Health::Service.new, create_qa: false
      @user = user
      @service = service
      @create_qa = create_qa
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      update
    end

    def update
      @service.class.transaction do
        @service.save!
        if @create_qa
          @qualifying_activity.source_id = @service.id
          @qualifying_activity.save
        end
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @service.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.current,
        activity: 'Connection to community and social services',
        follow_up: 'Provide services to patient',
        reached_client: 'Yes (face to face, phone call answered, response to email)',
        mode_of_contact: 'In Person',
        patient_id: @service.patient_id
      )
    end


  end
end
