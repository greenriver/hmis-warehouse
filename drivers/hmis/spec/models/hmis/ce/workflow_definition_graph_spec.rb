###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::WorkflowDefinition::Graph, type: :model do
  let!(:template) { create(:hmis_workflow_definition_template) }
  let!(:start_event) { create(:hmis_workflow_definition_start_event, template: template, name: 'Start Event') }
  let!(:gateway) { create(:hmis_workflow_definition_gateway, template: template, name: 'Gateway') }
  let!(:task1) { create(:hmis_workflow_definition_user_task, template: template, name: 'Task 1') }
  let!(:task2) { create(:hmis_workflow_definition_user_task, template: template, name: 'Task 2') }
  let!(:end1) { create(:hmis_workflow_definition_end_event, template: template, name: 'End 1') }
  let!(:task2a) { create(:hmis_workflow_definition_user_task, template: template, name: 'Task 2a') }
  let!(:end2) { create(:hmis_workflow_definition_end_event, template: template, name: 'End 2') }

  #     start_event
  #          |
  #       gateway
  #       /    \
  #    task1  task2
  #     |        |
  #    end1   task2a
  #              |
  #            end2

  before do
    start_event.connect_to!(gateway)
    gateway.connect_to!(task1, condition: 'foo = 1')
    gateway.connect_to!(task2)
    task1.connect_to!(end1)
    task2.connect_to!(task2a)
    task2a.connect_to!(end2)
  end

  describe 'graph walk nodes' do
    it 'returns all nodes' do
      nodes = template.graph.walk.to_a
      expect(nodes.count).to eq(7)
      expect(nodes[0]).to eq(start_event)
      expect(nodes[1]).to eq(gateway)
      expect(nodes[2]).to eq(task1)
      expect(nodes[3]).to eq(end1)
      expect(nodes[4]).to eq(task2)
      expect(nodes[5]).to eq(task2a)
      expect(nodes[6]).to eq(end2)
    end

    it 'returns correct nodes when passed an entrypoint' do
      nodes = template.graph.walk(entrypoint_ids: [task2.id]).to_a
      expect(nodes.count).to eq(2)
      expect(nodes[0]).to eq(task2a)
      expect(nodes[1]).to eq(end2)
    end

    it 'stops after a stop condition' do
      nodes = template.graph.walk(stop_when: lambda(&:user_task?)).to_a
      expect(nodes.count).to eq(4)
      expect(nodes[0]).to eq(start_event)
      expect(nodes[1]).to eq(gateway)
      # it DOES include the nodes that "trigger" the stop condition; it just doesn't traverse or include their children
      expect(nodes[2..3]).to contain_exactly(task1, task2)
    end

    it 'stops on the next node with the stop condition, even if the entrypoint meets the condition' do
      nodes = template.graph.walk(entrypoint_ids: [task2.id], stop_when: lambda(&:user_task?)).to_a
      expect(nodes.count).to eq(1)
      expect(nodes[0]).to eq(task2a)
    end
  end
end
