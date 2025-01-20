FactoryBot.define do
  factory :hmis_workflow_execution_instance, class: 'Hmis::WorkflowExecution::Instance' do
    association(:template, factory: :hmis_workflow_definition_template)
  end
end
