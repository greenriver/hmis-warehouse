###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class OtherService < Service

    def title
      "Other Service: #{other_type}"
    end

    def slug
      :other
    end
  end
end
