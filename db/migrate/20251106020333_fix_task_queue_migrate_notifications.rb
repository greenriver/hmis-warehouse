###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FixTaskQueueMigrateNotifications < ActiveRecord::Migration[7.1]
  def up
    # Fix and requeue a task that failed
    TaskQueue.where(task_key: 'migrate_user_notification_preferences', completed_at: nil).
      where.not(started_at: nil).
      destroy_all
    Delayed::Job.where.not(failed_at: nil).
      where(attempts: 3).
      jobs_for_class(['TaskQueue']).
      destroy_all
  end
end
