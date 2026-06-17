###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ServiceScanning
  class BedNight < Service
    def title
      'Bed-Night'
    end

    def slug
      :bed_night
    end
  end
end
