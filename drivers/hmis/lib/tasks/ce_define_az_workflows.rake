# frozen_string_literal: true

# CE workflow definitions for the AZ installation.
# CAUTION: Deletes existing referrals and opportunities associated with these templates,
# so that we don't have to worry about definitions shifting underfoot.
# This means it should NOT be run in production after the first time!
# Usage: rails driver:hmis:ce_define_az_workflows
desc 'Create CE workflow definitions for AZ'
task ce_define_az_workflows: [:environment] do
  raise 'This task destroys data and should not be run in production!' if Rails.env.production?
  raise unless HmisEnforcement.hmis_enabled?

  puts 'Enabling CE in AppConfigProperty'
  ce_enabled = AppConfigProperty.find_or_initialize_by(key: 'hmis_ce/enabled')
  ce_enabled.value = true
  ce_enabled.save! if ce_enabled.changed?

  # Expect one DS in client-specific env. Raise if we find more than one.
  # This task should be adapted to accept a data source ID if we want to run it in a multi-OP-HMIS environment such as QA.
  data_source = GrdaWarehouse::DataSource.hmis.sole

  # Keep custom statuses in sync
  puts 'Ensuring custom statuses are in sync'
  CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)

  puts "Creating workflow templates in data source #{data_source.id} (#{data_source.name})"

  templates = []
  Hmis::Hud::Base.transaction do
    builder = CeWorkflows::Az::WorkflowBuilder.new(data_source)
    templates << builder.build_mc_direct_referral_workflow
  end

  puts 'Generated Mermaid Diagrams:'
  puts templates.map(&:to_mermaid_diagram).join("\n\n")
end
