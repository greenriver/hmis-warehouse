# frozen_string_literal: true

module Hmis::Ce
  # todo @martha - probably the name "stepper" could be clearer.
  # add some comments here and on the real stepper explaining what this does
  class DryRunEngineStepper
    def call(step, symbol)
      step.send(symbol)
      # do NOT save
    end
  end
end
