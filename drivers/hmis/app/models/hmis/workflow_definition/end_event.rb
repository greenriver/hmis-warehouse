###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Represents the conclusion of a workflow path.
# End events may trigger final actions such as notifications or state changes when reached.
module Hmis::WorkflowDefinition
  class EndEvent < Node
    # events must have at least one trigger
    validates :trigger_config, presence: true

    def endpoint? = true
  end
end
