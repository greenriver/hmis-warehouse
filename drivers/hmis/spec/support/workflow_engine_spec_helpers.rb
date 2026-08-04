###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Reusable, workflow-agnostic helpers for driving a Hmis::WorkflowExecution::Engine through its
# steps in specs and asserting on the resulting state. Kept separate from any particular workflow's
# fixtures so it can be shared across workflow specs.
module WorkflowEngineSpecHelper
  # Find the currently-open step named `step_name`, submit `submitted_values` for it, and advance the engine.
  def complete_user_step!(engine, step_name, submitted_values:, user:)
    step = engine.active_steps.find { |s| s.node.name == step_name }
    raise "No active step named #{step_name}" unless step

    step.form_definition = step.node.form_definition
    engine.start_step!(step, user: user)
    engine.complete_step!(step, user: user, submitted_values: submitted_values)
  end

  # Assert the exact set of currently-open steps. Using contain_exactly (rather than a `find`) catches
  # both steps that should have opened but didn't and steps that should have closed but stayed open.
  def expect_active_steps(engine, *names)
    expect(engine.active_steps.map { |s| s.node.name }).to contain_exactly(*names)
  end

  # Drive the engine through an ordered list of [step_name, submitted_values] pairs.
  def drive!(engine, steps, user:)
    steps.each do |step_name, submitted_values|
      complete_user_step!(engine, step_name, submitted_values: submitted_values, user: user)
    end
  end
end

RSpec.configure do |config|
  config.include WorkflowEngineSpecHelper
end
