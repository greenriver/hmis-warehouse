###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Tells a reviewer that a project they manage has new external form submissions.
#
# Never include client PII or submission content: this mailer receives only IDs and a count, and
# must not load FormSubmission records (raw_data and notes are PII).
class HmisExternalApis::ExternalFormSubmissionNotificationMailer < ::DatabaseMailer
  # Mailers don't pick up the driver view paths registered in config/initializers/driver_setup.rb
  prepend_view_path File.expand_path('../../views', __dir__)

  # Project dashboard route for the External Forms review queue in the HMIS frontend.
  # See ProjectDashboardRoutes.EXTERNAL_FORM_SUBMISSIONS in hmis-frontend/src/routes/routes.ts
  REVIEW_QUEUE_SUBPATH = 'external-form-submissions'

  def new_submissions(user_id:, project_id:, new_count:)
    @user = User.active.find_by(id: user_id)
    @project = Hmis::Hud::Project.find_by(id: project_id)
    return unless @user && @project

    @new_count = new_count
    @url = @project.data_source.hmis_url_for(@project, user: @user, subpath: REVIEW_QUEUE_SUBPATH)
    mail(to: @user.email, subject: 'New external form submissions to review')
  end
end
