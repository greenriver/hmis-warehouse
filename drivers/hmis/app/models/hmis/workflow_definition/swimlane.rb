# frozen_string_literal: true

# Swimlanes help organize tasks by responsibility and are used to determine task assignments.
module Hmis::WorkflowDefinition
  class Swimlane < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :tasks, class_name: 'Hmis::WorkflowDefinition::UserTask', dependent: :nullify
    has_many :default_swimlane_assignments, class_name: 'Hmis::Ce::DefaultSwimlaneAssignment', dependent: :destroy
  end
end
