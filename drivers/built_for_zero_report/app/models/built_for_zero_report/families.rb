###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Families
    include ActiveModel::Model
    attr_accessor :families

    def initialize(start_date, end_date)
      @families = Calculator.new(:adult_and_child_cohort, start_date, end_date)
    end
  end
end
