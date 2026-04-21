# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'dentaku'

module Hmis::CalculatedField
  # May combine with Hmis::Ce::Match::Expression::CalculatorFactory ?
  module CalculatorFactory
    def self.build
      Dentaku::Calculator.new(case_sensitive: true)
    end
  end
end
