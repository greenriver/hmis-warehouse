###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Pii::Scrubber
  # Replace present PII values with per-record placeholders
  class StaticScrubber
    def perform(fields)
      fields.each do |field|
        next unless Pii::Scrubber::ReplacementPii.static_type?(field)
        next if field.real_value.nil?

        field.scrub(Pii::Scrubber::ReplacementPii.static_value(field, id: field.record_id))
      end
    end
  end
end
