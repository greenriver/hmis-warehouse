###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  module QueuedReportJobs
    extend ActiveSupport::Concern

    private

    # Returns [run_at, unsaved report] pairs for the queued jobs the current user may see.
    def queued_reports(handler)
      Delayed::Job.jobs_for_class(handler).order(run_at: :desc).filter_map do |job|
        job_data = YAML.load(job.handler, permitted_classes: [ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper]).job_data
        parameters = ActiveJob::Arguments.deserialize(job_data['arguments']).first
        next unless parameters.is_a?(Hash)

        report = report_source.new(parameters: parameters, user_id: parameters[:current_user_id])
        # Matches GrdaWarehouse::WarehouseReports::Base.visible_to for finished reports.
        next unless current_user.can_view_all_reports? || report.user_id == current_user.id

        [job.run_at, report]
      end
    end
  end
end
