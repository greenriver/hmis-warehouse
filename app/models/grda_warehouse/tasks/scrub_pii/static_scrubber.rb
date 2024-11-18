###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module GrdaWarehouse::Tasks::ScrubPii
  # replace PII attributes with fake values
  class StaticScrubber
    def perform(fields)
      fields.each do |field|
        value = GrdaWarehouse::Tasks::ScrubPii::ReplacementPii.static_value(field)
        field.scrub(value) unless value.nil?
      end
    end
  end
end
