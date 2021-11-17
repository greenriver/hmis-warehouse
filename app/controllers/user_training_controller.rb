###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserTrainingController < ApplicationController
  include NotifierConfig

  def test_log_url_in_error_notifications
    if request[:remote_ip] = '54.85.171.61'
      setup_notifier('TestingLogURLInNotification')
      @notifier.ping('test @notifier.ping')
      @notifier.post(text: 'test @notifier.post')
      begin
        foo = testExceptionNotifierNotifyException
      rescue => e
        ExceptionNotifier.notify_exception(e)
      end
    else
      render :plain => 'Nope ' + request[:remote_ip]
    end
  end

  def index
    config = Talentlms::Config.first
    if config.nil? || !current_user.training_required? || current_user.training_completed?
      redirect_to after_sign_in_path_for(current_user)
    else
      lms = Talentlms::Facade.new

      begin
        lms.login(current_user)

        # Ensure the user is enrolled in the course
        lms.enroll(current_user, config.courseid)

        completed_on = lms.complete?(current_user, config.courseid)
        if completed_on.present?
          current_user.update(training_completed: true, last_training_completed: completed_on.to_date)
          redirect_to after_sign_in_path_for(current_user)
        else
          # Construct TalentLMS Course URL
          redirect_url = if current_user.can_access_some_client_search?
            clients_url
          else
            root_url
          end
          course_url = lms.course_url(current_user, config.courseid, redirect_url, logout_talentlms_url)

          redirect_to course_url
        end
      rescue RuntimeError => e
        @message = e.message
      end
    end
  end
end
