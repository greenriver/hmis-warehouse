###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Represents a task that does not require user action.
# It completes (and performs any triggers/side effects) as soon as it is enabled.
module Hmis::WorkflowDefinition
  class ScriptTask < Node
    def script_task? = true
  end
end
