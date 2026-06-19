###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
