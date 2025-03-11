# frozen_string_literal: true

module Hmis::Ce
  class ReferralEngineStepper
    def call(step, symbol)
      step.send(symbol)
      step.save!
    end
  end
end
