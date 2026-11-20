###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

##
# Copies the definition rows of a workflow template (template, swimlanes, nodes, flows) into a new,
# fully independent template. The copy keeps no ids or foreign keys pointing at the source, so changing
# or deleting either template afterwards has no effect on the other.
#
# Setup tooling, run from a Rails console. Not used by runtime application logic.
# Only adds rows: the source template and everything outside the template definition (unit groups,
# units, match rules, candidate pools, default contacts, referrals) are left untouched and are not copied.
#
# What the copy gets:
# - Every live swimlane, node, and flow, as new rows. Soft-deleted rows are skipped.
# - data_source_id, template_type, and description from the source. Owner is left nil.
# - version 0, status draft (unless publish: true).
#
# Raises, creating nothing, if any template already uses the identifier (including a soft-deleted one),
# if a live node or flow points at a row that wasn't copied, or if the copy fails Template#validate!
# (so an unfinished draft can't be copied).
#
# Usage:
#   source = Hmis::WorkflowDefinition::Template.published.find_by!(identifier: 'housing_workflow_v1')
#   copy = CeWorkflows::Shared::TemplateCloner.new(
#     source,
#     identifier: 'housing_workflow_family',
#     name: 'Family Housing Referral Workflow',
#   ).call
#
#   # Edit the copy's rows, then check and publish it
#   copy.nodes.find_by!(name: 'Initial Review').update!(name: 'Family Review')
#   copy.validate!
#   puts copy.to_mermaid_diagram
#   CeWorkflows::Shared::CeBuilderUtils.publish_template(template: copy)
#
#   # Then set the new identifier on a unit group that has no template yet
#
# @see docs/features/hmis/ce-workflow-builders.md
module CeWorkflows::Shared
  class TemplateCloner
    # @param source_template [Hmis::WorkflowDefinition::Template] the template version to copy
    # @param identifier [String] identifier for the new template; must not be used by any template, including soft-deleted ones
    # @param name [String] name for the new template
    # @param publish [Boolean] publish the copy after creating it; by default it stays a draft
    def initialize(source_template, identifier:, name:, publish: false)
      @source_template = source_template
      @identifier = identifier
      @name = name
      @publish = publish
    end

    # @return [Hmis::WorkflowDefinition::Template] the new template
    def call
      Hmis::WorkflowDefinition::Template.transaction do
        check_preconditions!

        template = create_template
        swimlane_id_map = copy_swimlanes(template)
        node_id_map = copy_nodes(template, swimlane_id_map)
        copy_flows(template, node_id_map)

        template.validate!
        CeBuilderUtils.publish_template(template: template) if @publish
        template
      end
    end

    private

    def check_preconditions!
      raise ArgumentError, 'identifier is required' if @identifier.blank?

      identifier_taken = Hmis::WorkflowDefinition::Template.
        with_deleted.
        where(identifier: @identifier).
        exists?
      raise ArgumentError, "A template with identifier '#{@identifier}' already exists (possibly soft-deleted)" if identifier_taken

      raise ArgumentError, "Source template #{@source_template.id} has no nodes" unless @source_template.nodes.exists?
    end

    def create_template
      # Owner is left nil on purpose: whoever creates a copy should choose its owner, not inherit the source's.
      Hmis::WorkflowDefinition::Template.create!(
        identifier: @identifier,
        name: @name,
        version: 0,
        status: 'draft',
        data_source_id: @source_template.data_source_id,
        template_type: @source_template.template_type,
        description: @source_template.description,
      )
    end

    # @return [Hash{Integer => Integer}] source swimlane id => new swimlane id
    def copy_swimlanes(template)
      source_swimlanes = @source_template.swimlanes.order(:id)

      source_swimlanes.each_with_object({}) do |source_swimlane, id_map|
        new_swimlane = Hmis::WorkflowDefinition::Swimlane.create!(
          template: template,
          name: source_swimlane.name,
        )
        id_map[source_swimlane.id] = new_swimlane.id
      end
    end

    # @return [Hash{Integer => Integer}] source node id => new node id
    def copy_nodes(template, swimlane_id_map)
      source_nodes = @source_template.nodes.order(:id)

      source_nodes.each_with_object({}) do |source_node, id_map|
        new_swimlane_id = map_swimlane_id(source_node, swimlane_id_map)

        # Use the source node's STI class so the copy is the same node type
        new_node = source_node.class.create!(
          template: template,
          name: source_node.name,
          trigger_config: source_node.trigger_config,
          form_definition_identifier: source_node.form_definition_identifier,
          gateway_type: source_node.gateway_type,
          swimlane_id: new_swimlane_id,
        )
        id_map[source_node.id] = new_node.id
      end
    end

    # A nil swimlane stays nil. Any other swimlane must have been copied; fetch raises otherwise
    # (for example, when a live node points at a soft-deleted swimlane).
    def map_swimlane_id(source_node, swimlane_id_map)
      source_swimlane_id = source_node.swimlane_id
      return nil if source_swimlane_id.nil?

      swimlane_id_map.fetch(source_swimlane_id) do
        raise KeyError, "Node #{source_node.id} (#{source_node.name}) points at swimlane #{source_swimlane_id}, " \
          'which is soft-deleted or belongs to another template'
      end
    end

    def copy_flows(template, node_id_map)
      source_flows = @source_template.flows.order(:id)

      source_flows.each do |source_flow|
        # fetch raises if a live flow points at a node that wasn't copied (for example, a soft-deleted node)
        new_source_node_id = map_node_id(source_flow, source_flow.source_node_id, node_id_map)
        new_target_node_id = map_node_id(source_flow, source_flow.target_node_id, node_id_map)

        # Create directly rather than with Node#connect_to!, so the template is set explicitly
        Hmis::WorkflowDefinition::Flow.create!(
          template: template,
          source_node_id: new_source_node_id,
          target_node_id: new_target_node_id,
          condition: source_flow.condition,
          position: source_flow.position,
        )
      end
    end

    def map_node_id(source_flow, source_node_id, node_id_map)
      node_id_map.fetch(source_node_id) do
        raise KeyError, "Flow #{source_flow.id} points at node #{source_node_id}, " \
          'which is soft-deleted or belongs to another template'
      end
    end
  end
end
