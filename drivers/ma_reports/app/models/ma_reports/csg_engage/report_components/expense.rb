###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaReports::CsgEngage::ReportComponents
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
