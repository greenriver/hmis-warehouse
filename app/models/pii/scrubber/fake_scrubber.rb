###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module Pii::Scrubber
  # replace PII attributes with fake values
  class FakeScrubber
    def perform(fields)
      fields.each do |field|
        value = Pii::Scrubber::ReplacementPii.fake_value(field)
        field.scrub(value) unless value.nil?
      end
    end
  end
end
