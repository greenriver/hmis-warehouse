###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Used to enqueue tasks that should be run once.
# The pattern is something like:
#
# Initializer - inject class into a list
# iterate over the list in the cron job
# If there is a record for that class in the table with no queued_at, then queue a job (and mark it queued)
# To re-run a task, insert a new row with a blank queued_at value
class TaskQueue < ApplicationRecord
  # Marking something as inactive indicates that it should be re-queued
  scope :active, -> do
    where(active: true)
  end

  scope :queued, -> do
    where(queued_at: nil)
  end

  # The expectation is that if the task is in available_tasks, then it should be in the queue
  def self.queue_unprocessed!
    done = active.pluck(:task_key, :queued_at).to_h
    available_tasks.each do |task_key, _|
      next if done[task_key].present?

      t = TaskQueue.create(task_key: task_key)
      t.delay.run!
      t.update(queued_at: Time.current)
    end
  end

  def self.available_tasks
    Rails.application.config.queued_tasks
  end

  def run!
    to_run = self.class.available_tasks[task_key.to_sym]
    if to_run.blank?
      # Re-queue the task, it's possible we are just running on old code
      update(queued_at: nil)
      # But also notify that we had a potentially serious problem
      raise "Unknown task key: #{task_key}"
    end

    update(started_at: Time.current)
    to_run.call
    update(completed_at: Time.current)
  end
end
