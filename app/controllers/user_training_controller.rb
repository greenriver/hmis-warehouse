###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class UserTrainingController < ApplicationController
  def index
    config = Talentlms::Config.first
    if current_user.training_completed? || !current_user.training_required? || config.nil?
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
        logout_url = request.base_url + '/logout_talentlms'
        redirect_url = request.base_url + after_sign_in_path_for(current_user)
        course_url = lms.course_url(current_user, config.courseid, redirect_url, logout_url)

        redirect_to course_url
      end
    end
  end
end
