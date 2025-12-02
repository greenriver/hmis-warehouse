# CE workflow definition for PH
# Usage: rails driver:hmis:ce_define_ph_workflow
desc 'Create a CE workflow definition for PH'
task ce_define_ph_direct_workflow: [:environment] do
  raise 'This task destroys data and should not be run in production!' if Rails.env.production?
  raise unless HmisEnforcement.hmis_enabled?

  puts 'Enabling CE in AppConfigProperty'
  ce_enabled = AppConfigProperty.find_or_initialize_by(key: 'hmis_ce/enabled')
  ce_enabled.value = true
  ce_enabled.save! if ce_enabled.changed?

  data_source = GrdaWarehouse::DataSource.hmis.order(:id).first

  # Keep custom statuses in sync
  CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)

  puts "Creating workflow template in data source #{data_source.id} (#{data_source.name})"

  builder = CeWorkflows::Ph::WorkflowBuilder.new(data_source)
  template = builder.build_direct_referral_workflow

  puts 'Generated Mermaid Diagram:'
  puts template.to_mermaid_diagram
end
