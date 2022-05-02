###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Chronic
    include ActiveModel::Model
    attr_accessor :chronic
    alias data chronic

    def initialize(start_date, end_date)
      @chronic = Calculator.new(:chronic_cohort, start_date, end_date)
    end
  end
end
