###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Validates Workflow Templates - all nodes are reachable, there is a start and (at least one) end node, etc.
# Does not inherit from ActiveModel::Validator, since we don't want these validations to run as part of lifecycle hooks,
# because it's convenient to be able to save the workflow template before creating its nodes and flows.
# Some of these checks could be validators on the Node subclasses (like EndEvent and StartEvent), but everything lives
# here to keep the validation logic in one place.
class Hmis::WorkflowDefinition::Validators::WorkflowTemplateValidator
  def validate(record)
    validate_start(record)
    validate_end(record)
    validate_tasks_and_gateways(record)
    validate_nodes_reachable(record)
  end

  private

  def validate_start(record)
    unless record.nodes.entrypoints.count == 1
      record.errors.add(:base, 'There must be exactly one start event.')
      return
    end

    start = record.nodes.entrypoints.sole

    record.errors.add(:base, 'Start event must have at least one outflow.') unless start.outflows.any?
    record.errors.add(:base, 'Start event must not have any inflows.') if start.inflows.any?
  end

  def validate_end(record)
    endpoints = record.nodes.endpoints
    record.errors.add(:base, 'There must be at least one end event.') unless endpoints.any?

    without_inflows = endpoints.filter { |end_event| end_event.inflows.none? }
    record.errors.add(:base, "The following end events have no inflows: #{without_inflows.map(&:name).join(', ')}") if without_inflows.any?

    with_outflows = endpoints.filter { |end_event| end_event.outflows.any? }
    record.errors.add(:base, "The following end events have outflows: #{with_outflows.map(&:name).join(', ')}") if with_outflows.any?
  end

  def validate_tasks_and_gateways(record)
    invalid_nodes = (record.nodes.gateways + record.nodes.tasks).filter { |node| node.inflows.none? || node.outflows.none? }
    record.errors.add(:base, "The following nodes must have at least one inflow and one outflow: #{invalid_nodes.map(&:name).join(', ')}") if invalid_nodes.any?

    record.nodes.gateways.filter { |gateway| gateway.outflows.map(&:condition).all? }.each do |gateway|
      record.errors.add(:base, "Gateway '#{gateway.name}' must have at least one non-conditional (default) outflow.")
    end
  end

  def validate_nodes_reachable(record)
    unreachable = record.graph.unreachable_nodes
    record.errors.add(:base, "The following nodes are unreachable: #{unreachable.map(&:name).join(', ')}") if unreachable.any?
  end
end
