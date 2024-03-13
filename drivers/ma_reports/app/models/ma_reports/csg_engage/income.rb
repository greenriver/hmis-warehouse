###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Income < Base
    attr_accessor :income_benefit

    def initialize(income_benefit)
      @income_benefit = income_benefit
    end

    field('Test') { 'TODO' }
  end
end
