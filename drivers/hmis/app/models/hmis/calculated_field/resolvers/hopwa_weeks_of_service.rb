# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::CalculatedField::Resolvers
  class HopwaWeeksOfService
    def call(_client)
      raise NotImplementedError, 'HopwaWeeksOfService resolver not yet implemented'
    end

    private

    def fiscal_year_start
      today = Date.current
      today.month >= 7 ? Date.new(today.year, 7, 1) : Date.new(today.year - 1, 7, 1)
    end

    def fiscal_year_end
      fiscal_year_start + 1.year - 1.day
    end
  end
end
