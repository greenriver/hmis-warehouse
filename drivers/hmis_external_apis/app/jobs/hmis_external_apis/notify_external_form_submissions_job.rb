###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Email reviewers about new external form submissions in projects that have opted in with an
# EXTERNAL_FORM_SUBMISSION_NOTIFICATIONS project config.
#
# Order matters for failure handling: compute every recipient's payload, then enqueue the emails,
# then stamp. If the compute phase raises, nothing has been sent or stamped and the next run starts
# clean. Emails are delivered in their own jobs so a failed send doesn't affect other recipients.
class HmisExternalApis::NotifyExternalFormSubmissionsJob < BaseJob
  queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

  def perform
    return unless HmisExternalApis::ConsumeExternalFormSubmissionsJob.enabled?

    instrument_as_maintenance_task do |run|
      with_lock do
        _perform
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

  def _perform
    # Load only the columns needed for counting; raw_data and notes are large and contain PII
    pending = submission_class.
      where(reviewers_notified_at: nil).
      select(:id, :definition_id, :status).
      preload(:definition).
      to_a
    return if pending.empty?

    payloads = build_payloads(pending)
    payloads.each do |payload|
      mailer_class.new_submissions(**payload).deliver_later
    end

    # Stamp by the IDs loaded above, so a submission ingested mid-run isn't stamped before it's evaluated
    submission_class.where(id: pending.map(&:id)).update_all(reviewers_notified_at: Time.current)
  end

  # @return [Array<Hash>] one entry per recipient: { user_id:, data_source_id:, project_counts: { 'project_id' => new_count } }
  def build_payloads(pending)
    counts_by_project = opted_in_project_counts(pending)
    return [] if counts_by_project.empty?

    counts_by_project_id = counts_by_project.transform_keys(&:id)
    projects_by_data_source_id = counts_by_project.keys.group_by(&:data_source_id)

    projects_by_data_source_id.flat_map do |data_source_id, projects|
      project_ids = projects.map(&:id)
      candidates = Hmis::User.active.not_system.with_hmis_access_in_data_source(data_source_id)

      # Load fresh user instances per data source; policies are memoized per instance and depend on hmis_data_source_id
      candidates.find_each.filter_map do |user|
        user.hmis_data_source_id = data_source_id
        reviewable_ids = Hmis::Hud::Project.
          with_access(user, :can_manage_external_form_submissions).
          where(id: project_ids).
          pluck(:id)
        next if reviewable_ids.empty?

        project_counts = reviewable_ids.to_h { |id| [id.to_s, counts_by_project_id.fetch(id)] }
        { user_id: user.id, data_source_id: data_source_id, project_counts: project_counts }
      end
    end
  end

  # @return [Hash{Hmis::Hud::Project => Integer}] count of new submissions for opted-in projects that have any
  def opted_in_project_counts(pending)
    new_by_definition_id = pending.
      select { |s| s.status == 'new' }.
      group_by(&:definition_id)

    counts = Hash.new(0)
    new_by_definition_id.each do |definition_id, submissions|
      project = review_project(definition_id, submissions.first.definition)
      next unless project
      next unless opted_in?(project)

      counts[project] += submissions.size
    end
    counts
  end

  # The project whose review queue shows submissions for this definition. Same rule as
  # FormSubmission#parent_project, but reports and skips instead of raising so one misconfigured
  # form doesn't block notifications for other projects. Skipped submissions are still stamped.
  def review_project(definition_id, definition)
    unless definition
      report_skipped(
        'form definition not found',
        definition_id: definition_id,
      )
      return
    end

    instances = definition.instances.active.for_projects.to_a
    if instances.size != 1
      report_skipped(
        'form definition does not have exactly one active project instance',
        definition_id: definition_id,
        instance_count: instances.size,
      )
      return
    end

    project = instances.first.entity
    unless project
      report_skipped(
        'project not found for active form instance',
        definition_id: definition_id,
        instance_id: instances.first.id,
      )
    end
    project
  end

  # Keep IDs out of the message so Sentry groups repeat events
  def report_skipped(reason, **extra)
    Sentry.capture_message("#{self.class.name}: skipping submissions, #{reason}", extra: extra)
  end

  def opted_in?(project)
    Hmis::ProjectExternalFormSubmissionNotificationConfig.detect_best_config_for_project(project).present?
  end

  def with_lock(&block)
    lock_name = self.class.name.demodulize
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end

  def submission_class
    HmisExternalApis::ExternalForms::FormSubmission
  end

  def mailer_class
    HmisExternalApis::ExternalFormSubmissionNotificationMailer
  end
end
