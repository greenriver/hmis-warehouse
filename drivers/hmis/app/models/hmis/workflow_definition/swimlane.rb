# frozen_string_literal: true

# Swimlanes help organize tasks by responsibility and are used to determine task assignments.
module Hmis::WorkflowDefinition
  class Swimlane < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :tasks, class_name: 'Hmis::WorkflowDefinition::Task', dependent: :nullify
  end
end
