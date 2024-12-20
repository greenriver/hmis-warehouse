module Hmis::WorkflowDefinition
  class Task < Node
    belongs_to :form_definition, class_name: 'Hmis::Form::Definition'
    belongs_to :assigned_to, class_name: 'Hmis::User', optional: true

    validates :name, presence: true

    def task? = true
  end
end
