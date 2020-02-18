###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class UserTrainingController < ApplicationController
  def index
    config = Talentlms::Config.first
    if config.nil? || !current_user.training_required? || current_user.training_completed?
      redirect_to after_sign_in_path_for(current_user)
    else
      lms = Talentlms::Facade.new
      # Ensure the user is enrolled in the course
      lms.enroll(current_user, config.courseid)

      if lms.complete?(current_user, config.courseid)
        current_user.update(training_completed: true)
        redirect_to after_sign_in_path_for(current_user)
      else
        # Construct TalentLMS Course URL
        redirect_url = if can_access_some_client_search?
          clients_url
        else
          root_url
        end
        course_url = lms.course_url(current_user, config.courseid, redirect_url, logout_talentlms_url)

        redirect_to course_url
      end
    end
  end
end
