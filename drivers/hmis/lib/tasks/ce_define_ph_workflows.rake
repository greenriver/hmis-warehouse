# frozen_string_literal: true

# CE workflow definition for PH
# Usage:
#   rails driver:hmis:ce_define_ph_workflows                # creates draft templates. Idempotent; if templates already exist as draft, they will be updated.
#   rails driver:hmis:ce_define_ph_workflows PUBLISH=true   # creates and publishes templates. Once the templates are published, this task will error if you try to run it again.
desc 'Create CE workflow definitions for PH'
task ce_define_ph_workflows: [:environment] do
  raise unless HmisEnforcement.hmis_enabled?

  # Parse publish option (defaults to false)
  publish = ENV['PUBLISH']&.downcase == 'true'

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

  puts "Updating workflow templates in data source #{data_source.id} (#{data_source.name})"

  builder = CeWorkflows::Ph::WorkflowBuilder.new(data_source)

  puts 'Ensuring decline reasons are in sync'
  builder.ensure_decline_reasons

  templates = []
  Hmis::Hud::Base.transaction do
    templates << builder.build_benefits_referral_workflow
    templates << builder.build_shelter_referral_workflow
    templates << builder.build_outreach_referral_workflow

    puts 'Template Mermaid Diagrams:'
    puts templates.map(&:to_mermaid_diagram).join("\n\n")

    if publish
      puts 'Publishing templates...'
      templates.each do |template|
        CeWorkflows::Shared::CeBuilderUtils.publish_template(template: template)
      end
      puts 'Templates published successfully'
    else
      puts 'Skipping publishing (PUBLISH=false). Templates have been created as draft.'
    end
  end
end
