###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::WorkflowDefinition::Validators::WorkflowTemplateValidator, type: :model do
  let!(:template) { create(:hmis_workflow_definition_template, status: 'draft') }
  let!(:start) { create(:hmis_workflow_definition_start_event, template: template, name: 'Start Event') }
  let!(:accept) { create(:hmis_workflow_definition_end_event, template: template, name: 'Client Accepted') }
  let!(:reject) { create(:hmis_workflow_definition_end_event, template: template, name: 'Client Rejected') }
  let!(:step_def) { create(:ce_referral_step_form_definition) }
  let!(:task) { create(:hmis_workflow_definition_task, template: template, name: 'Client Acceptance', form_definition: step_def) }
  let!(:gateway) { create(:hmis_workflow_definition_gateway, template: template, name: 'Gateway') }

  # Basic valid workflow. The rest of the tests modify it to be invalid in different ways
  #
  #     start
  #       |
  #     task
  #       |
  #    gateway
  #    /     \
  # accept  reject

  before do
    start&.connect_to!(task)
    task.connect_to!(gateway)
    gateway.connect_to!(accept, condition: 'client_accepted = true') if accept.present?
    gateway.connect_to!(reject) if reject.present?
    template.reload
  end

  describe 'Valid workflow' do
    it 'is valid' do
      template.validate
      expect(template.errors).to be_empty
    end
  end

  describe 'Workflow with no start event' do
    let!(:start) { nil }

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('There must be exactly one start event.')
    end
  end

  describe 'Workflow with too many start events' do
    let!(:start_2) { create(:hmis_workflow_definition_start_event, template: template, name: 'Invalid 2nd Start') }

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('There must be exactly one start event.')
    end
  end

  describe 'Workflow with start event that has an inflow' do
    let!(:invalid_task) { create(:hmis_workflow_definition_task, template: template, name: 'Invalid Task') }

    before do
      invalid_task.connect_to!(start)
      template.reload
    end

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('Start event must not have any inflows.')
    end
  end

  describe 'Workflow with start event that has no outflows' do
    before do
      start.outflows.destroy_all
      template.reload
    end

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('Start event must have at least one outflow.')
    end
  end

  describe 'Workflow with no end event' do
    let!(:accept) { nil }
    let!(:reject) { nil }

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('There must be at least one end event.')
    end
  end

  describe 'Workflow with end event that has no inflows' do
    before do
      accept.inflows.destroy_all
      template.reload
    end

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('The following end events have no inflows: Client Accepted')
    end
  end

  describe 'Workflow with end event that has outflows' do
    let!(:invalid_task) { create(:hmis_workflow_definition_task, template: template, name: 'Invalid Task') }

    before do
      accept.connect_to!(invalid_task)
      template.reload
    end

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('The following end events have outflows: Client Accepted')
    end
  end

  describe 'Workflow with unreachable node' do
    let!(:unreachable) { create(:hmis_workflow_definition_task, template: template, name: 'Unreachable') }

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('The following nodes are unreachable: Unreachable')
    end
  end

  describe 'Workflow with gateway that is a dead end' do
    before do
      gateway.outflows.destroy_all
      template.reload
    end

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include('The following nodes must have at least one inflow and one outflow: Gateway')
    end
  end

  describe 'Workflow with gateway that does not have a default outflow' do
    before do
      gateway.outflows.destroy_all
      gateway.connect_to!(accept, condition: 'client_accepted = true')
      gateway.connect_to!(reject, condition: 'client_accepted = false')
      template.reload
    end

    it 'is not valid' do
      template.validate
      expect(template.errors[:base]).to include("Gateway 'Gateway' must have at least one non-conditional (default) outflow.")
    end
  end
end
