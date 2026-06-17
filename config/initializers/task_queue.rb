###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Register one-time queued tasks
# See TaskQueue.register_tasks for task definitions
Rails.application.config.after_initialize do
  TaskQueue.register_tasks(Rails.application.config)
end
