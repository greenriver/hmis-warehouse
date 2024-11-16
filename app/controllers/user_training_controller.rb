###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserTrainingController < ApplicationController
  def index
    lms = Talentlms::Facade.new(current_user)
    courses = current_user.required_training_courses
    configs = courses.flat_map(&:config).uniq

    # Verifying with local data before hitting the API. This prevents unneeded API calls
    # and ensures local data is updated when new trainings have been completed.
    if !lms.any_training_required?
      redirect_to after_sign_in_path_for(current_user)
    else

      begin
        course_redirects = []
        # Make sure the user has a login setup for each config
        # Pulling this out here to prevent duplicate API calls for courses that share a configuration
        configs.each do |config|
          lms.login(config)
        end
        # Check each course traininig for progress/expiration
        courses.each do |course|
          config = course.config
          course_id = course.courseid

          # Ensure the user is enrolled in the course
          lms.enroll(config, course_id)

          # reset progress if course is expired (check against API competion date)
          lms.reset_user_progress(config, course_id) if lms.training_expired?(config, course_id)

          completed_on = lms.complete?(config, course_id)
          if completed_on.present?
            lms.log_course_completion(config, course_id, completed_on)
            current_user.update(training_completed: true, last_training_completed: completed_on.to_date)
          else
            # Construct TalentLMS Course URL
            redirect_url = if current_user.can_search_own_clients?
              clients_url
            else
              root_url
            end
            course_url = lms.course_url(config, course_id, redirect_url, logout_talentlms_url)

            course_redirects << course_url
          end
        end

        if course_redirects.present?
          # redirect to the course training
          redirect_to course_redirects.first, allow_other_host: true
        else
          # All trainings are completed
          redirect_to after_sign_in_path_for(current_user)
        end
      rescue RuntimeError => e
        @message = e.message
      end
    end
  end
end
