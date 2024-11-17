###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# replace PII attributes
module GrdaWarehouse::Tasks::ScrubPii
  class DefaultScrubber
    def perform(fields)
      fields.each do |field|
        field.scrub(nil)
      end
    end
  end
end
