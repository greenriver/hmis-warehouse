###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class DateTime < BaseScalar
    description 'A DateTime object, transporated as a string'

    def self.coerce_input(input_value)
      DateTime.parse(input_value)
    end

    def self.coerce_result(ruby_value)
      ruby_value.to_s
    end
  end
end
