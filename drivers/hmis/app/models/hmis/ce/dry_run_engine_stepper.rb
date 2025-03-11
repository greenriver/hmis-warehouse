# frozen_string_literal: true

module Hmis::Ce
  class DryRunEngineStepper
    def call(step, symbol)
      # this isn't quite going to wkr but you get thpeot
      step.send(symbol)
      # do NOT save
    end
  end
end
