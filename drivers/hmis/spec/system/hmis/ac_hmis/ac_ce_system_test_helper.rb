###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Shared context for AC CE workflow system tests. Sets up workflows and cleans up after.
RSpec.shared_context 'ac ce workflows' do
  before(:all) do
    ds1 = GrdaWarehouse::DataSource.find_or_create_by!(hmis: 'localhost', source_type: :sftp, name: 'HMIS', short_name: 'HMIS')

    HmisUtil::JsonForms.new(env_key: 'allegheny', enable_cded_generation_in_test: true).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP, :ENROLLMENT]) # Seed enrollment form so it collects units
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(ds1)
    workflow_builder = CeWorkflows::Ac::WorkflowBuilder.new(ds1)
    workflow_builder.build_housing_workflow
    workflow_builder.build_admin_assign_workflow
  end

  after(:all) do
    # Clean up data source after deleting dependent records.
    # It's not auto-cleaned up because it's created in before(:all) and not in a fixture
    Hmis::WorkflowDefinition::Flow.delete_all
    Hmis::WorkflowDefinition::Node.delete_all
    Hmis::WorkflowDefinition::Swimlane.delete_all
    Hmis::WorkflowDefinition::Template.delete_all
    Hmis::Ce::CustomReferralStatus.delete_all
    GrdaWarehouse::DataSource.hmis.delete_all

    # Return enrollment form to normal. (See comment about form cleanup in rails_helper.rb)
    HmisUtil::JsonForms.new.seed_record_form_definitions(roles: [:ENROLLMENT])

    # Cleanup seeded referral step forms that were created in before(:all)
    Hmis::Form::Definition.where(role: :CE_REFERRAL_STEP).delete_all
    Hmis::Hud::CustomDataElementDefinition.delete_all
    Hmis::Hud::CustomDataElement.delete_all
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'ac ce workflows', include_shared: true
end
