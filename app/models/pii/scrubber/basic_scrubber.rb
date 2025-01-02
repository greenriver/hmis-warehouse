###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module Pii::Scrubber
  # replace PII attributes with fake values
  class BasicScrubber
    def perform(fields, id:)
      fields.each do |field|
        value = field.required? ? Pii::Scrubber::ReplacementPii.static_value(field, id: id) : nil
        field.scrub(value)
      end
    end
  end
end
