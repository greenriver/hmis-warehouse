###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
