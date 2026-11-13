# frozen_string_literal: true

# CE housing workflow definition for PH
# Usage:
#   rails driver:hmis:ce_define_ph_housing_workflows
desc 'Create CE housing workflow definitions for PH'
task ce_define_ph_housing_workflows: [:environment] do
  raise 'This task destroys data and should not be run in production!' if Rails.env.production?
  raise unless HmisEnforcement.hmis_enabled?
  raise unless Hmis::Ce.configuration.enabled?

  # Expect one DS in client-specific env. Raise if we find more than one.
  # This task should be adapted to accept a data source ID if we want to run it in a multi-OP-HMIS environment such as QA.
  data_source = GrdaWarehouse::DataSource.hmis.sole

  # Keep custom statuses in sync
  puts 'Ensuring custom statuses are in sync'
  CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)

  builder = CeWorkflows::Ph::HousingWorkflowBuilder.new(data_source)

  puts "Creating workflow template in data source #{data_source.id} (#{data_source.name})"
  templates = []
  Hmis::Hud::Base.transaction do
    templates << builder.build_housing_workflow
  end

  puts 'Generated Mermaid Diagrams:'
  puts templates.map(&:to_mermaid_diagram).join("\n\n")
end
