###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Date < BaseScalar
    description 'A Date object, transporated as a string'

    def self.coerce_input(input_value, _context)
      Date.parse(input_value)
    end

    def self.coerce_result(ruby_value, _context)
      ruby_value.to_s(:db)
    end
  end
end
