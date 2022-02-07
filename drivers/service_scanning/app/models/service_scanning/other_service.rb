###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class OtherService < Service
    def title
      "Other Service: #{other_type}"
    end

    def title_only
      'Other Service'
    end

    def slug
      :other
    end
  end
end
