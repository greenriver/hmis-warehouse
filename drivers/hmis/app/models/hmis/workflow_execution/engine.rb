###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'dentaku'

# Manages the execution of workflow instances, handling state transitions,
# task assignments, and message processing according to the workflow template.
module Hmis::WorkflowExecution
  class Engine
    attr_reader :template, :instance, :message_handler, :assignment_handler

    def initialize(workflow_instance, message_handler:, assignment_handler:)
      @instance = workflow_instance
      @template = workflow_instance.template
      @message_handler = message_handler
      @assignment_handler = assignment_handler
    end

    def active_steps
      instance.steps.where(status: ['available', 'in_progress'])
    end

    def start_workflow!(user:)
      template.nodes.entrypoints.each do |node|
        visit_node(node, user)
      end
      log_event('start_workflow', user: user)
    end

    def start_step!(step, user:)
      step.start!
      process_triggers(node: step.node, event_type: 'start_step', user: user, step: step)
      log_event('start_step', user: user, step: step)
    end

    def validate_step(step, submitted_values:)
      definition = step.form_definition # form_definition is optional on step; it is populated when the step is submitted, so here we expect it to be present.
      definition.validate_form_values(submitted_values)
    end

    def complete_step!(step, user:, submitted_values:)
      step.submitted_values = submitted_values
      step.complete!
      process_triggers(node: step.node, event_type: 'complete_step', user: user, step: step)
      log_event('complete_step', user: user, step: step, event_data: submitted_values)
      traverse_node(step.node, user)
    end

    # user (admin) rolls-back completion
    def undo_complete_step!(step, user:)
      raise ArgumentError, 'cannot rollback step' unless may_undo_complete_step?(step)

      next_task_steps(step).each(&:disable!)
      log_event('undo_complete_step', user: user, step: step)
      step.undo_complete_step!
    end

    def may_undo_complete_step?(step)
      step.may_undo_complete_step?
      next_task_steps(step).all?(&:may_disable?)
    end

    # def cancel_step!(step)
    #   step.cancel!
    # end

    protected

    # get all tasks nodes under step but treat those task nodes as leaves and stop searching (bounded depth-first search)
    def next_task_steps(step)
      nodes = template.graph.walk(entrypoint_ids: [step.node_id], stop_when: lambda(&:task?))
      steps_by_node_id = instance.steps.index_by(&:node_id)
      nodes.map { |node| steps_by_node_id[node.id] }.compact
    end

    def send_message(...)
      message = Hmis::WorkflowExecution::Message.new(...)
      message_handler.call(message)
    end

    def process_triggers(node:, event_type:, user:, step: nil)
      results = node.triggers.map do |trigger|
        next unless event_type == trigger.event

        result = send_message(
          type: trigger.message,
          params: trigger.params,
          step: step,
          user: user,
        )

        log_event('message_sent', event_data: trigger.to_h) if result[:success?]
        result
      end

      step&.update!(reversible: false) unless results.compact.all?(&:reversible?)
      results
    end

    def traverse_node(node, user)
      return if node.endpoint?

      if node.join_inflows?
        return unless node.inflows.all? { |flow| evaluate_condition(flow.condition) }
      end

      outflows = node.outflows.sort_by(&:position)
      if node.exclusive_outflows?
        outflows = Array(outflows.detect { |flow| evaluate_condition(flow.condition) })
      else
        outflows = outflows.filter { |flow| evaluate_condition(flow.condition) }
      end

      raise "Node (#{node.id}) blocks flow. It should have a default outflow" if outflows.empty?

      process_triggers(node: node, event_type: 'pass_gateway', user: user) if node.gateway?
      outflows.each { |flow| visit_node(flow.target_node, user) }
    end

    def visit_node(node, user)
      case node
      when Hmis::WorkflowDefinition::Task
        step = instance.steps.find_or_initialize_by(node: node)

        # If the step has already been completed, it may be re-openable, but _only_ if it didn't have any irreversible side effects
        if step.status == 'completed' && !step.reversible? # rubocop:disable Style/IfUnlessModifier
          raise "Failed to reopen step #{step.id} because it had an irreversible side effect. This indicates a misconfigured workflow."
        end

        step.enable!
        assign_task!(step)
      when Hmis::WorkflowDefinition::Gateway
        traverse_node(node, user)
      when Hmis::WorkflowDefinition::StartEvent
        process_triggers(node: node, event_type: 'start_workflow', user: user)
        traverse_node(node, user)
      when Hmis::WorkflowDefinition::EndEvent
        process_triggers(node: node, event_type: 'end_workflow', user: user)
      else
        raise "Got unhandled node #{node.class.name}"
      end
    end

    def assign_task!(step)
      assignment_handler.call(step.node).each do |user|
        step.assignments.create!(user: user)
      end
    end

    # Evaluate a workflow condition expression.
    # Example:
    #   'client_accepted = 0'
    #   where 'client_accepted is a submitted value on any completed step
    def evaluate_condition(expression)
      # empty expression defaults to true
      return true if expression.blank?

      calculator = Dentaku::Calculator.new
      defaults = calculator.dependencies(expression).to_h { |k| [k.to_sym, nil] }
      calculator.evaluate!(expression, **defaults.merge(all_submitted_values.transform_keys(&:to_sym)))
    end

    def all_submitted_values
      instance.steps.reset
      steps_by_node_id = instance.steps.index_by(&:node_id)
      template.graph.walk.each.with_object({}) do |node, result|
        step = steps_by_node_id[node.id]
        result.merge!(step.submitted_values) if step&.completed?
      end
    end

    def log_event(event_type, user: nil, event_data: nil, step: nil)
      instance.audit_events.create!(event_type: event_type, user: user, event_data: event_data, step: step)
    end
  end
end
