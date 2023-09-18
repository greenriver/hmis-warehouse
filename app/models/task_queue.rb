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

  # NOTE: there is a completed_at timestamp, but this scope is simply that the queuing has happened
  scope :completed, -> do
    where.not(queued_at: nil)
  end

  # The expectation is that if the task is in available_tasks, then it should be in the queue
  def self.queue_unprocessed!
    done = active.pluck(:rake_task, :queued_at).to_h
    available_tasks.each do |task|
      next if done[task].present?

      t = TaskQueue.create(rake_task: task)
      t.queue!
    end
  end

  def self.available_tasks
    Rails.application.config.queued_tasks
  end

  def queue!
    Rake::Task[rake_task].delay.invoke
    update(queued_at: Time.current)
  end
end
