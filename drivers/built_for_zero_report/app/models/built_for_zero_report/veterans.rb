###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Veterans
    include ActiveModel::Model
    attr_accessor :veterans
    attr_accessor :chronic_veterans

    def initialize(start_date, end_date)
      @veterans = Calculator.new(:veteran_cohort, start_date, end_date)
      @chronic_veterans = Calculator.new(:chronic_cohort, start_date, end_date, client_ids: @veterans.actively_homeless.keys)
    end
  end
end
