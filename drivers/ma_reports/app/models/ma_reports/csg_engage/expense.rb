###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Expense < Base
    attr_accessor :base

    def initialize(base)
      @base = base
    end

    field('Annually')
    field('Code')
    field('Description')
    field('PayeeName')
  end
end
