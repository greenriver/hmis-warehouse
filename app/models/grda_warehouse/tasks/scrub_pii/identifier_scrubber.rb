###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# replace PII attributes with static text
module GrdaWarehouse::Tasks::ScrubPii
  class IdentifierScrubber
    TYPES_VALUES = [:first_name, :last_name, :middle_name].to_h do |type|
      [type, type.to_s.camelize]
    end

    def perform(fields)
      fields.each do |field|
        next unless TYPES_VALUES.key?(field.type)

        field.scrub("#{TYPES_VALUES[field.type]}#{field.record_id}")
      end
    end
  end
end
