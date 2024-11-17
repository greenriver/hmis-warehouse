###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# replace PII attributes
module GrdaWarehouse::Tasks::ScrubPii
  # scrub all sensitive fields that have not yet been scrubbed
  class DefaultScrubber
    # max_level: sanitize fields below this sensitivity level
    def perform(fields, max_level: 3)
      candidates = fields.filter do |field|
        !field.scrubbed? && field.level < max_level
      end
      candidates.each do |field|
        field.scrub(nil)
      end
    end
  end
end
