# frozen_string_literal: true

# Swimlanes help organize tasks by responsibility and are used to determine task assignments.
module Hmis::WorkflowDefinition
  class Swimlane < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :tasks, class_name: 'Hmis::WorkflowDefinition::UserTask', dependent: :nullify
    has_many :default_swimlane_assignments, class_name: 'Hmis::Ce::DefaultSwimlaneAssignment', dependent: :destroy

    scope :viewable_by, ->(user) do
      joins(:template).merge(Hmis::WorkflowDefinition::Template.viewable_by(user))
    end

    scope :ce, -> { joins(:template).merge(Hmis::WorkflowDefinition::Template.ce) }

    scope :used_in_project, ->(project) do
      joins(:template).merge(Hmis::WorkflowDefinition::Template.published.used_in_projects([project.id]))
    end
  end
end
