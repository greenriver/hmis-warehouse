###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module GrdaWarehouse::Tasks::ScrubPii
  # replace PII attributes with fake values
  class BasicScrubber
    def perform(fields)
      fields.each do |field|
        value = field.required? ? GrdaWarehouse::Tasks::ScrubPii::ReplacementPii.static_value(field) : nil
        field.scrub(value)
      end
    end
  end
end
