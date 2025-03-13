# frozen_string_literal: true

module Hmis::Ce
  # The Stepper is a dependency injected into the workflow engine, responsible for calling methods on steps.
  # This one, the regular referral engine stepper, calls step methods like step.start! and step.complete!,
  # saving changes to the DB. (Compare to DryRunEngineStepper)
  class ReferralEngineStepper
    def call(step, symbol)
      step.send(symbol)
      step.save!
    end
  end
end
