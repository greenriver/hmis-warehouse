# frozen_string_literal: true

# STI Base class for all workflow nodes (tasks, events, gateways).
# Nodes are the building blocks of a workflow template and represent points where work is performed, decisions are made, or events occur.
module Hmis::WorkflowDefinition
  class Node < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :outflows, class_name: 'Hmis::WorkflowDefinition::Flow', foreign_key: 'source_node_id', dependent: :destroy
    has_many :inflows, class_name: 'Hmis::WorkflowDefinition::Flow', foreign_key: 'target_node_id', dependent: :destroy

    validate :check_trigger_config_format

    scope :entrypoints, -> { where(type: 'Hmis::WorkflowDefinition::StartEvent') }
    scope :endpoints, -> { where(type: 'Hmis::WorkflowDefinition::EndEvent') }
    scope :gateways, -> { where(type: 'Hmis::WorkflowDefinition::Gateway') }
    scope :user_tasks, -> { where(type: 'Hmis::WorkflowDefinition::UserTask') }
    scope :script_tasks, -> { where(type: 'Hmis::WorkflowDefinition::ScriptTask') }

    # helpers to avoid node.is_a?(WidgetType)
    def entrypoint? = false
    def endpoint? = false
    def user_task? = false
    def script_task? = false
    def gateway? = false
    def join_inflows? = false
    def exclusive_outflows? = false

    # [
    #   { event: 'step_completed', message: 'send_notification', params: params },
    # ]
    def triggers
      (trigger_config || []).map { |item| OpenStruct.new(item) }
    end

    # helper for connecting nodes
    def connect_to!(target_node, condition: nil, position: nil)
      position ||= (outflows.map(&:position).max || 0) + 1
      outflows.create!(
        template: template,
        target_node: target_node,
        position: position,
        condition: condition,
      )
    end

    def conditional_inflows?
      inflows.map(&:condition).any?
    end

    def describe_as_string
      str = "[#{type.demodulize}] #{name} (#{id})"
      inflow_descriptions = inflows.order(:position).map { |flow| flow.describe_as_string(source_only: true) }
      str += "\n   Inflows:\n     #{inflow_descriptions.join("\n     ")}" if inflow_descriptions.any?
      outflow_descriptions = outflows.order(:position).map { |flow| flow.describe_as_string(target_only: true) }
      str += "\n   Outflows:\n     #{outflow_descriptions.join("\n     ")}" if outflow_descriptions.any?
      str
    end

    # Returns a string representation of the node for Mermaid diagrams
    def to_mermaid_node
      base_name = name

      # Add trigger information if present
      if triggers.any?
        trigger_descriptions = triggers.map do |trigger|
          parts = ["EVENT: #{trigger.event.humanize.titleize} → #{trigger.message.humanize.titleize}"]
          if trigger.params.present?
            # Format params for Mermaid compatibility, avoiding problematic characters
            parts << "PARAMS: #{trigger.params.map { |k, v| "#{k}: #{v}" }.join(', ')}"
          end
          parts.join('<br/>')
        end

        base_name += "<br/><br/>#{trigger_descriptions.join('<br/>---<br/>')}"
      end

      if entrypoint? || endpoint?
        "#{to_mermaid_node_id}((\"#{base_name}\"))"
      elsif gateway?
        "#{to_mermaid_node_id}{\"#{base_name}\"}"
      else
        "#{to_mermaid_node_id}(\"#{base_name}\")"
      end
    end

    # Returns unique identifier for the node to use in Mermaid diagrams
    def to_mermaid_node_id
      "#{name.parameterize(separator: '_')}_#{id}"
    end

    protected

    def check_trigger_config_format
      return unless trigger_config.is_a?(Array)

      trigger_config.each_with_index do |item, index|
        next if item.is_a?(Hash) && item['event'].present? && item['message'].present?

        errors.add(:config_data, "item at index #{index} is invalid: #{item.inspect}")
      end
    end
  end
end
