###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CeWorkflows::Shared::TemplateCloner do
  let(:template_class) { Hmis::WorkflowDefinition::Template }
  let(:swimlane_class) { Hmis::WorkflowDefinition::Swimlane }
  let(:node_class) { Hmis::WorkflowDefinition::Node }
  let(:flow_class) { Hmis::WorkflowDefinition::Flow }

  # Snapshot of every definition row (including soft-deleted ones) so we can prove nothing changed
  def definition_row_snapshot
    [template_class, swimlane_class, node_class, flow_class].to_h do |klass|
      rows = klass.with_deleted.order(:id).map(&:attributes)
      [klass.name, rows]
    end
  end

  def row_counts
    [template_class, swimlane_class, node_class, flow_class].to_h do |klass|
      [klass.name, klass.with_deleted.count]
    end
  end

  # An id-free description of a template's graph. Sorted arrays (not sets), so a missing copy of a
  # repeated node name is still caught.
  def graph_fingerprint(template)
    swimlane_names = template.swimlanes.pluck(:id, :name).to_h
    nodes = template.nodes.to_a

    node_fingerprints = nodes.to_h do |node|
      fingerprint = [
        node.type,
        node.name,
        swimlane_names[node.swimlane_id],
        node.form_definition_identifier,
        node.gateway_type,
        node.trigger_config,
      ]
      [node.id, fingerprint]
    end

    flow_fingerprints = template.flows.map do |flow|
      [
        node_fingerprints.fetch(flow.source_node_id),
        node_fingerprints.fetch(flow.target_node_id),
        flow.condition,
        flow.position,
      ]
    end

    {
      nodes: node_fingerprints.values.sort_by(&:to_json),
      flows: flow_fingerprints.sort_by(&:to_json),
    }
  end

  describe 'on a factory-built graph' do
    let(:data_source) { create(:hmis_data_source) }
    let!(:source) do
      create(
        :hmis_workflow_definition_template,
        data_source: data_source,
        description: 'Source description',
        owner_type: 'GrdaWarehouse::DataSource',
        owner_id: data_source.id,
      )
    end

    let(:status_trigger_config) do
      [
        {
          'event' => 'enable_step',
          'message' => 'set_custom_referral_status',
          'params' => { 'custom_status_key' => 'matching_in_progress' },
        },
      ]
    end
    let(:decline_trigger_config) do
      [
        { 'event' => 'end_workflow', 'message' => Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE },
        { 'event' => 'end_workflow', 'message' => 'set_ce_event_result', 'params' => { 'referral_result' => '2' } },
      ]
    end

    let!(:swimlane) { create(:hmis_workflow_definition_swimlane, template: source, name: 'CE Staff') }
    let!(:start_event) do
      create(
        :hmis_workflow_definition_start_event,
        template: source,
        name: 'Start',
        trigger_config: [{ 'event' => 'start_workflow', 'message' => 'start_referral' }],
      )
    end
    let!(:user_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: source,
        name: 'Initial Review',
        swimlane: swimlane,
        trigger_config: status_trigger_config,
      )
    end
    let!(:gateway) do
      create(
        :hmis_workflow_definition_gateway,
        template: source,
        name: 'Move forward?',
        gateway_type: 'exclusive',
      )
    end
    let!(:script_task) { create(:hmis_workflow_definition_script_task, template: source, name: 'Notify') }
    let!(:accept_event) { create(:hmis_workflow_definition_end_event, template: source, name: 'Accepted') }
    let!(:decline_event) do
      create(
        :hmis_workflow_definition_end_event,
        template: source,
        name: 'Declined',
        trigger_config: decline_trigger_config,
      )
    end
    let!(:source_flows) do
      [
        start_event.connect_to!(user_task),
        user_task.connect_to!(gateway),
        gateway.connect_to!(script_task, condition: 'move_forward = 1', position: 1),
        gateway.connect_to!(decline_event, position: 2),
        script_task.connect_to!(accept_event),
      ]
    end

    def clone_source(**options)
      described_class.new(
        source,
        identifier: 'copied_workflow',
        name: 'Copied Workflow',
        **options,
      ).call
    end

    it 'is a valid source graph' do
      expect { source.validate! }.not_to raise_error
    end

    it 'copies every swimlane, node, and flow into new rows' do
      copy = clone_source

      expect(copy.swimlanes.count).to eq(source.swimlanes.count)
      expect(copy.nodes.count).to eq(source.nodes.count)
      expect(copy.flows.count).to eq(source.flows.count)

      expect(copy.swimlanes.pluck(:id)).not_to include(*source.swimlanes.pluck(:id))
      expect(copy.nodes.pluck(:id)).not_to include(*source.nodes.pluck(:id))
      expect(copy.flows.pluck(:id)).not_to include(*source.flows.pluck(:id))
    end

    it 'keeps no references between the copy and the source' do
      copy = clone_source

      [[copy, source], [source, copy]].each do |template, other|
        swimlane_ids = swimlane_class.with_deleted.where(template_id: template.id).pluck(:id)
        node_ids = node_class.with_deleted.where(template_id: template.id).pluck(:id)
        other_swimlane_ids = swimlane_class.with_deleted.where(template_id: other.id).pluck(:id)
        other_node_ids = node_class.with_deleted.where(template_id: other.id).pluck(:id)

        node_swimlane_ids = node_class.where(id: node_ids).pluck(:swimlane_id).compact
        expect(node_swimlane_ids - swimlane_ids).to be_empty
        expect(node_swimlane_ids & other_swimlane_ids).to be_empty

        flow_node_ids = flow_class.where(template_id: template.id).pluck(:source_node_id, :target_node_id).flatten
        expect(flow_node_ids - node_ids).to be_empty
        expect(flow_node_ids & other_node_ids).to be_empty
      end
    end

    it 'keeps descriptive attributes on nodes and flows' do
      copy = clone_source

      expect(graph_fingerprint(copy)).to eq(graph_fingerprint(source))
      expect(copy.nodes.find_by!(name: 'Initial Review').trigger_config).to eq(status_trigger_config)
      expect(copy.nodes.find_by!(name: 'Move forward?').gateway_type).to eq('exclusive')
      expect(copy.nodes.find_by!(name: 'Initial Review').form_definition_identifier).to eq(user_task.form_definition_identifier)
      expect(copy.swimlanes.pluck(:name)).to eq(['CE Staff'])
    end

    it 'does not change the source' do
      before_snapshot = definition_row_snapshot
      copy = clone_source
      after_snapshot = definition_row_snapshot

      after_snapshot.each do |class_name, rows|
        copy_key = class_name == template_class.name ? 'id' : 'template_id'
        rows_outside_copy = rows.reject { |attrs| attrs[copy_key] == copy.id }
        expect(rows_outside_copy).to eq(before_snapshot[class_name])
      end
      expect(source.reload.status).to eq('published')
    end

    it 'copies template attributes, without the owner, as a draft at version 0' do
      copy = clone_source

      expect(copy).to have_attributes(
        identifier: 'copied_workflow',
        name: 'Copied Workflow',
        version: 0,
        status: 'draft',
        data_source_id: source.data_source_id,
        template_type: source.template_type,
        description: 'Source description',
        owner_type: nil,
        owner_id: nil,
      )
    end

    it 'publishes the copy when asked' do
      copy = clone_source(publish: true)

      expect(copy.reload.status).to eq('published')
    end

    it 'does not copy soft-deleted swimlanes, nodes, or flows' do
      deleted_swimlane = create(:hmis_workflow_definition_swimlane, template: source, name: 'Deleted Lane')
      deleted_node = create(:hmis_workflow_definition_script_task, template: source, name: 'Deleted Node')
      user_task.connect_to!(deleted_node)
      deleted_node.connect_to!(accept_event)
      deleted_flow = start_event.connect_to!(decline_event)

      deleted_swimlane.destroy!
      deleted_node.destroy! # also soft-deletes its flows
      deleted_flow.destroy!

      copy = clone_source

      expect(copy.swimlanes.pluck(:name)).to eq(['CE Staff'])
      expect(copy.nodes.pluck(:name)).not_to include('Deleted Node')
      expect(copy.flows.count).to eq(source_flows.size)
      expect(graph_fingerprint(copy)).to eq(graph_fingerprint(source))
    end

    context 'when copying would raise' do
      def expect_raise_and_nothing_created(error_class, message = nil)
        counts_before = row_counts
        expect { clone_source }.to raise_error(error_class, message)
        expect(row_counts).to eq(counts_before)
      end

      it 'raises when a live node points at a soft-deleted swimlane' do
        # update_column rather than destroy!, which would nullify the tasks' swimlane_id
        swimlane.update_column(:deleted_at, Time.current)

        expect_raise_and_nothing_created(KeyError, /points at swimlane/)
      end

      it 'raises when a live flow points at a soft-deleted node' do
        # update_column rather than destroy!, which would also soft-delete the node's flows
        script_task.update_column(:deleted_at, Time.current)

        expect_raise_and_nothing_created(KeyError, /points at node/)
      end

      it 'raises when the copy fails template validation' do
        # A node with no inflows or outflows makes the graph invalid
        create(:hmis_workflow_definition_script_task, template: source, name: 'Orphan')

        expect_raise_and_nothing_created(ActiveRecord::RecordInvalid)
      end

      it 'raises when the identifier is already used' do
        create(:hmis_workflow_definition_template, identifier: 'copied_workflow', data_source: data_source, status: 'draft')

        expect_raise_and_nothing_created(ArgumentError)
      end

      it 'raises when the identifier is used by a soft-deleted template' do
        existing = create(:hmis_workflow_definition_template, identifier: 'copied_workflow', data_source: data_source)
        existing.destroy!

        expect_raise_and_nothing_created(ArgumentError)
      end

      it 'raises when the identifier is blank' do
        counts_before = row_counts

        cloner = described_class.new(source, identifier: '  ', name: 'Copied Workflow')

        expect { cloner.call }.to raise_error(ArgumentError, /identifier is required/)
        expect(row_counts).to eq(counts_before)
      end

      it 'raises when the source has no nodes' do
        empty_source = create(:hmis_workflow_definition_template, data_source: data_source)
        counts_before = row_counts

        cloner = described_class.new(empty_source, identifier: 'copied_workflow', name: 'Copied Workflow')

        expect { cloner.call }.to raise_error(ArgumentError, /has no nodes/)
        expect(row_counts).to eq(counts_before)
      end
    end
  end

  describe 'on the Standard referral workflow built by its builder' do
    let(:data_source) { create(:hmis_data_source) }
    let(:source) do
      CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)
      HmisUtil::JsonForms.new(
        data_source_id: data_source.id,
        env_key: 'demo',
        generate_cdeds: true,
      ).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])

      builder = CeWorkflows::Standard::WorkflowBuilder.new(data_source)
      builder.ensure_decline_reasons
      draft_template = builder.build_standard_referral_workflow
      CeWorkflows::Shared::CeBuilderUtils.publish_template(template: draft_template)
      draft_template.reload
    end

    it 'produces a valid copy with the same graph as the source' do
      copy = described_class.new(
        source,
        identifier: 'standard_referral_copy',
        name: 'Standard Referral Copy',
      ).call

      source_fingerprint = graph_fingerprint(source)
      copy_fingerprint = graph_fingerprint(copy)

      expect(source_fingerprint[:nodes]).not_to be_empty
      expect(copy_fingerprint).to eq(source_fingerprint)
      expect { copy.validate! }.not_to raise_error
      expect(source.reload.status).to eq('published')
      expect(copy.status).to eq('draft')
    end
  end
end
