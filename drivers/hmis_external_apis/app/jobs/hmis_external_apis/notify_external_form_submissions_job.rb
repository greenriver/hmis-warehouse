###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Email a project's reviewers about new submissions in its External Forms review queue, if the
# project has opted in with an EXTERNAL_FORM_SUBMISSION_NOTIFICATIONS project config.
#
# Order matters for failure handling: find the recipients, then enqueue the emails, then stamp. If
# finding recipients raises, nothing has been sent or stamped and the next run starts clean. Emails
# are delivered in their own jobs so a failed send doesn't affect other recipients.
class HmisExternalApis::NotifyExternalFormSubmissionsJob < BaseJob
  queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

  # One job per project that has an active external form
  def self.perform_later_for_review_projects
    project_ids = Hmis::Form::Instance.
      with_role(:EXTERNAL_FORM).
      for_projects.
      active.
      pluck(:entity_id).
      uniq
    project_ids.each { |project_id| perform_later(project_id: project_id) }
  end

  def perform(project_id:)
    return unless HmisExternalApis::ConsumeExternalFormSubmissionsJob.enabled?

    project = Hmis::Hud::Project.find_by(id: project_id)
    return unless project

    instrument_as_maintenance_task do |run|
      with_lock(project) do
        _perform(project)
        run.complete!
      end
    end
  end

  # A retry after enqueueing but before stamping would send duplicate emails. Unstamped submissions
  # are picked up by the next run, which ConsumeExternalFormSubmissionsJob enqueues hourly.
  def supports_idempotent_retry?
    false
  end

  protected

  # Submissions are stamped whether or not the project has opted in, so opting in later doesn't
  # email about the backlog
  def _perform(project)
    pending = submission_class.
      in_review_queue_for(project).
      where(reviewers_notified_at: nil).
      pluck(:id, :status)
    return if pending.empty?

    new_count = pending.count { |_id, status| status == 'new' }
    if new_count.positive? && opted_in?(project)
      reviewer_ids(project).each do |user_id|
        mailer_class.new_submissions(
          user_id: user_id,
          project_id: project.id,
          new_count: new_count,
        ).deliver_later
      end
    end

    # Stamp by the IDs loaded above, so a submission ingested mid-run isn't stamped before it's evaluated
    pending_ids = pending.map(&:first)
    submission_class.where(id: pending_ids).update_all(reviewers_notified_at: Time.current)
  end

  def reviewer_ids(project)
    candidates = Hmis::User.active.not_system.with_hmis_access_in_data_source(project.data_source_id)
    reviewers = candidates.find_each.select do |user|
      # Policies depend on the user's data source
      user.hmis_data_source_id = project.data_source_id
      Hmis::Hud::Project.
        with_access(user, :can_manage_external_form_submissions).
        where(id: project.id).
        exists?
    end
    reviewers.map(&:id)
  end

  def opted_in?(project)
    Hmis::ProjectExternalFormSubmissionNotificationConfig.detect_best_config_for_project(project).present?
  end

  def with_lock(project, &block)
    lock_name = "#{self.class.name.demodulize}:#{project.id}"
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end

  def submission_class
    HmisExternalApis::ExternalForms::FormSubmission
  end

  def mailer_class
    HmisExternalApis::ExternalFormSubmissionNotificationMailer
  end
end
