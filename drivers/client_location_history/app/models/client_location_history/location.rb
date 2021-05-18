###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory
  class Location < GrdaWarehouseBase
    belongs_to :source, polymorphic: true

    def as_point
      [lat, lon]
    end

    def as_label
      "Seen on: #{located_on} <br />by #{collected_by}".html_safe
    end
  end
end
