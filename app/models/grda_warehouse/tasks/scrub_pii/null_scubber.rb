###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ScrubPii
  class NullScrubber
    def perform(pii)
      pii.fields do |field|
        pii.scrub(nil)
      end
    end
  end
end
