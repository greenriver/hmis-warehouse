###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CustomImportsBostonCommunityOfOrigin
  class MaintainLocationHistoryJob
    def run!
      ::GrdaWarehouse::Hud::Enrollment.maintain_location_histories
    end
  end
end
