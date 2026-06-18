###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ServiceScanning
  class Outreach < Service
    def title
      'Outreach Contact'
    end

    def slug
      :outreach
    end
  end
end
