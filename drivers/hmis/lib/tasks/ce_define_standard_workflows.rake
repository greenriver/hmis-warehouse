###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :ce_define_standard_workflows do
  desc 'Creates and publishes a Standard Referral CE workflow template and its form definitions.'
  # Usage:
  #   rails driver:hmis:ce_define_standard_workflows:create[DATA_SOURCE_ID]   # explicit data source
  #   rails driver:hmis:ce_define_standard_workflows:create                   # expects sole HMIS data source
  # Optional: PUBLISH=true, FORCE_RECREATE=true, UNSAFE_RUN_IN_PRODUCTION=true
  task :create, [:data_source_id] => :environment do |_, args|
    raise unless HmisEnforcement.hmis_enabled?

    data_source = if args[:data_source_id].present?
      GrdaWarehouse::DataSource.hmis.find(args[:data_source_id])
    else
      GrdaWarehouse::DataSource.hmis.sole
    end

    unsafe_run_in_production = ENV['UNSAFE_RUN_IN_PRODUCTION']&.downcase == 'true'

    if ENV['FORCE_RECREATE']
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(
        'standard_referral',
        data_source: data_source,
        unsafe_run_in_production: unsafe_run_in_production,
      )
      CeWorkflows::Shared::CeBuilderUtils.delete_form_definitions(
        CeWorkflows::Standard::WorkflowBuilder::FORMS.values,
        data_source.id,
        unsafe_run_in_production: unsafe_run_in_production,
      )
      puts 'Re-seeding form definitions...'
      HmisUtil::JsonForms.new(data_source_id: data_source.id).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
    end

    builder = CeWorkflows::Standard::WorkflowBuilder.new(data_source)

    builder.ensure_decline_reasons

    template = builder.build_standard_referral_workflow
    CeWorkflows::Shared::CeBuilderUtils.publish_template(template: template) if ENV['PUBLISH']&.downcase == 'true'

    puts 'Template Mermaid Diagram:'
    puts template.reload.to_mermaid_diagram

    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)
  end
end
