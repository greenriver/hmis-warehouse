module Hmis::WorkflowExecution
  class Instance < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :steps, class_name: 'Hmis::WorkflowExecution::Step', dependent: :destroy
  end
end
