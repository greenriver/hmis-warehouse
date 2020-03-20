###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class EtoTouchPointsJob < BaseJob
    queue_as :low_priority

    def perform(touch_point_client_ids:)
      EtoApi::Tasks::UpdateEtoData.new(touch_point_client_ids: touch_point_client_ids).update_touch_points!
      GrdaWarehouse::Tasks::UpdateClientsFromHmisForms.new.run!
    end

    def max_attempts
      1
    end
  end
end
