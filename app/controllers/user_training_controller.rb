###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserTrainingController < ApplicationController
  def index
    config = Talentlms::Config.first
    lms = Talentlms::Facade.new

    # Verifying with local data before hitting the API. This prevents unneeded API calls
    # and ensures local data is updated when new trainings have been completed.
    if config.nil? || !lms.training_required?(current_user)
      redirect_to after_sign_in_path_for(current_user)
    else

      begin
        lms.login(current_user)
        # Ensure the user is enrolled in the course
        lms.enroll(current_user, config.courseid)

        # reset progress if course is expired (check against API competion date)
        lms.reset_user_progress(current_user) if lms.training_expired?(current_user)

        completed_on = lms.complete?(current_user, config.courseid)
        if completed_on.present?

          lms.log_course_completion(current_user, completed_on) if current_user.last_training_completed != completed_on.to_date
          current_user.update(training_completed: true, last_training_completed: completed_on.to_date)
          redirect_to after_sign_in_path_for(current_user)
        else
          # Construct TalentLMS Course URL
          redirect_url = if current_user.can_search_own_clients?
            clients_url
          else
            root_url
          end
          course_url = lms.course_url(current_user, config.courseid, redirect_url, logout_talentlms_url)

          redirect_to course_url, allow_other_host: true
        end
      rescue RuntimeError => e
        @message = e.message
      end
    end
  end
end
