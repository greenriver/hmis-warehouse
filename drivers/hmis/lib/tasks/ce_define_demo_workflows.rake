###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :ce_define_demo_workflows do
  desc 'Deletes existing demo CE workflow templates and form definitions.'
  task delete: :environment do
    raise 'This task destroys data and should not be run in production' if Rails.env.production?

    CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data('standard_referral')
    CeWorkflows::Shared::CeBuilderUtils.delete_form_definitions(CeWorkflows::Demo::WorkflowBuilder::FORMS.values)
  end

  desc 'Creates and publishes standard demo CE workflow templates and form definitions.'
  # Usage:
  #   rails driver:hmis:ce_define_demo_workflows:create[DATA_SOURCE_ID]
  # Optional: PUBLISH=true, FORCE_RECREATE=true
  task :create, [:data_source_id] => :environment do |_, args|
    raise unless HmisEnforcement.hmis_enabled?

    data_source_id = args[:data_source_id]
    if data_source_id.blank?
      raise ArgumentError, 'data_source_id is required. Example: rails driver:hmis:ce_define_demo_workflows:create[3]'
    end

    Rake::Task['driver:hmis:ce_define_demo_workflows:delete'].invoke if ENV['FORCE_RECREATE']

    data_source = GrdaWarehouse::DataSource.hmis.find(data_source_id)
    builder = CeWorkflows::Demo::WorkflowBuilder.new(data_source)

    builder.ensure_decline_reasons

    template = builder.build_standard_referral_workflow
    CeWorkflows::Shared::CeBuilderUtils.publish_template(template: template) if ENV['PUBLISH']&.downcase == 'true'

    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)
  end
end
