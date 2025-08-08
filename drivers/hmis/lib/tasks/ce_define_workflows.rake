# This task is for developing and iterating on CE workflow definitions.
# It will be run in staging/training environments until the workflows are ready, at which point we will run it in production.
# CAUTION: It deletes existing referrals and opportunities, so that we don't have to worry about definitions shifting underfoot.
# This means it should NOT be run in production after the first time!
# Usage: rails driver:hmis:ce_define_workflows
desc 'Script to create CE workflow definition'
task ce_define_workflows: [:environment] do
  raise 'This task destroys data and should not be run in production!' if Rails.env.production?
  raise unless HmisEnforcement.hmis_enabled?

  puts 'Enabling CE in AppConfigProperty'
  ce_enabled = AppConfigProperty.find_or_initialize_by(key: 'hmis_ce/enabled')
  ce_enabled.value = true
  ce_enabled.save! if ce_enabled.changed?

  data_source = GrdaWarehouse::DataSource.hmis.order(:id).first

  CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)

  puts "Creating workflow templates in data source #{data_source.id} (#{data_source.name})"
  templates = []
  Hmis::Hud::Base.transaction do
    ac_builder = CeWorkflows::Ac::WorkflowBuilder.new(data_source)
    templates << ac_builder.build_housing_workflow
    templates << ac_builder.build_admin_assign_workflow
  end

  # Write each diagram to a file in generated_diagrams/ to track changes in version control
  # Commented-out because the diagrams are not stable, they contain database IDs. I think this would be helpful to
  # add if we can generate stable diagrams.
  # if Rails.env.development?
  #   templates.each do |template|
  #     filename = File.join('drivers/hmis/lib/ce_workflows/generated_diagrams/', "#{template.identifier}.mmd")
  #     File.write(filename, template.to_mermaid_diagram)
  #   end
  # end

  puts 'Generated Mermaid Diagrams:'
  puts templates.map(&:to_mermaid_diagram).join("\n\n")
end
