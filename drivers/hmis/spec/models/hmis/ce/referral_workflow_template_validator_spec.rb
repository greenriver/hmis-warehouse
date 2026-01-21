###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::ReferralWorkflowTemplateValidator, type: :model do
  let(:template) { create(:hmis_workflow_definition_template, status: 'draft', template_type: 'ce_referral') }
  let(:start) { create(:hmis_workflow_definition_start_event, template: template, name: 'Start Event') }
  let(:accept) { create(:hmis_workflow_definition_end_event, template: template, name: 'Client Accepted') }
  let(:step_def) { create(:ce_referral_step_form_definition) }
  let(:task) do
    create(
      :hmis_workflow_definition_user_task,
      template: template,
      name: 'Client Acceptance',
      form_definition: step_def,
      trigger_config: [
        {
          event: 'complete_step',
          message: 'set_referral_decline_reason',
        },
      ],
    )
  end

  before do
    start.connect_to!(task)
    task.connect_to!(accept)
    template.reload
  end

  describe 'validate_decline_reasons' do
    context 'when the form does not collect decline reason' do
      let(:step_def) { create(:hmis_form_definition, role: 'CE_REFERRAL_STEP') }

      it 'adds an error' do
        template.validate
        expect(template.errors[:base]).to include("Decline reason form '#{step_def.identifier}' must collect decline reason on a choice item with link_id '#{Hmis::Ce::ReferralMessageHandler::DECLINE_REASON_LINK_ID}'")
      end
    end

    context 'when the form collects decline reason but the decline reason is not in the database' do
      it 'adds an error' do
        template.validate
        expect(template.errors[:base]).to include('The following decline reasons are collected by the form, but not defined in the database: user_error, client_not_interested')
      end
    end

    context 'when all decline reasons are in the database' do
      let(:user_error) { create(:ce_referral_decline_reason, key: 'user_error', data_source: template.data_source) }
      let(:client_not_interested) { create(:ce_referral_decline_reason, key: 'client_not_interested', data_source: template.data_source) }

      before do
        user_error
        client_not_interested
      end

      it 'is valid' do
        template.validate
        expect(template.errors).to be_empty
      end
    end
  end
end
