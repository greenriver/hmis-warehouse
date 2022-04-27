###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Adults
    include ActiveModel::Model
    attr_accessor :adults

    def initialize(start_date, end_date)
      @adults = Calculator.new(:adult_only_cohort, start_date, end_date)
    end
  end
end
