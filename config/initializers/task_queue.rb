# frozen_string_literal: true

# Register one-time queued tasks
# See TaskQueue.register_tasks for task definitions
Rails.application.config.after_initialize do
  TaskQueue.register_tasks(Rails.application.config)
end
