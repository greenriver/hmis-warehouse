###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonCommunityOfOrigin
  class MaintainLocationHistoryJob
    def run!
      ::GrdaWarehouse::Hud::Enrollment.maintain_location_histories
    end
  end
end
