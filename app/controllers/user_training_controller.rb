###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserTrainingController < ApplicationController
  def set_lms_info
    @courses = current_user.required_training_courses
    @configs = courses.flat_map(&:config).uniq
  end

  attr_reader :courses
  attr_reader :configs

  def index
    lms = Talentlms::Facade.new(current_user)
    set_lms_info

    # Verifying with local data before hitting the API. This prevents unneeded API calls
    # and ensures local data is updated when new trainings have been completed.
    if !lms.any_training_required?
      redirect_to after_sign_in_path_for(current_user)
    else

      begin
        course_redirects = []
        configs_with_required_courses = []
        config_logins = {}
        # Make sure the user has a login setup for each config
        # Pulling this out here to prevent duplicate API calls for courses that share a configuration
        configs.each do |config|
          config_logins[config.id] = lms.login(config)
        end

        # Check each course traininig for progress/expiration
        courses.each do |course|
          config = course.config
          course_id = course.courseid

          # Skip this course. This user does not have an account in this subdomain and
          # the subdomian has been flagged not to allow automated account creation.
          next unless config_logins[config.id]

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

            course_redirects << { course: course, url: course_url }
            configs_with_required_courses << config
          end
        end

        account_exists_in_all_configs = config_logins.values.all?(true)

        # If the user only has one required training course to complete, and that course's config
        # allows automatic redirects, send them directly to the training portal
        if course_redirects.present? && course_redirects.count == 1 && course_redirects.first[:course].config.allow_automatic_redirect_to_course
          # redirect to the course training
          redirect_to course_redirects.first[:url], allow_other_host: true
          return
        # If the user has an active account in all configs and has no trainings left to complete, allow them to navigate the warehouse
        elsif account_exists_in_all_configs && course_redirects.blank?
          # All trainings are completed and the user has an account in all training configs
          redirect_to after_sign_in_path_for(current_user)
          return
        end
        # For all other cases, send the user to the captive portal
        render 'required_trainings'
      rescue RuntimeError => e
        @message = e.message
        render 'error'
      end
    end
  end
end
