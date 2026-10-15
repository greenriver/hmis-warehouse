###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Tells reviewers that projects they manage have new external form submissions.
#
# Never include client PII or submission content: this mailer receives only IDs and counts, and
# must not load FormSubmission records (raw_data and notes are PII).
class HmisExternalApis::ExternalFormSubmissionNotificationMailer < ::DatabaseMailer
  # Mailers don't pick up the driver view paths registered in config/initializers/driver_setup.rb
  prepend_view_path File.expand_path('../../views', __dir__)

  # Project dashboard route for the External Forms review queue in the HMIS frontend.
  # See ProjectDashboardRoutes.EXTERNAL_FORM_SUBMISSIONS in hmis-frontend/src/routes/routes.ts
  REVIEW_QUEUE_SUBPATH = 'external-form-submissions'

  # @param project_counts [Hash{String => Integer}] new submission count by project ID. String keys
  #   because ActiveJob can't serialize integer hash keys.
  def new_submissions(user_id:, data_source_id:, project_counts:)
    @user = User.active.find_by(id: user_id)
    return unless @user

    data_source = GrdaWarehouse::DataSource.find(data_source_id)
    projects = Hmis::Hud::Project.where(data_source_id: data_source_id, id: project_counts.keys).order(:id)

    @project_rows = projects.map do |project|
      {
        name: project.project_name,
        new_count: project_counts.fetch(project.id.to_s),
        url: data_source.hmis_url_for(project, user: @user, subpath: REVIEW_QUEUE_SUBPATH),
      }
    end
    return if @project_rows.empty?

    mail(to: @user.email, subject: 'New external form submissions to review')
  end
end
