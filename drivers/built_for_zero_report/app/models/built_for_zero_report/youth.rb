###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Youth
    include ActiveModel::Model
    attr_accessor :youth

    def initialize(start_date, end_date)
      # FIXME: is this correct? The spec says 'unaccompanied', and this includes youth-only households.
      @youth = Calculator.new(:youth_cohort, start_date, end_date)
    end
  end
end
