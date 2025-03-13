# frozen_string_literal: true

module Hmis::Ce
  # The Stepper is a dependency injected into the workflow engine, responsible for calling methods on steps.
  # This one, the DryRun stepper, calls step methods like step.start and step.complete WITHOUT saving to the DB.
  # (step.start, not step.start!)
  class DryRunEngineStepper
    def call(step, symbol)
      step.send(symbol)
      # do NOT save
    end
  end
end
