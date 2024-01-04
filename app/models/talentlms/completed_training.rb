###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Talentlms
  class CompletedTraining < GrdaWarehouseBase
    self.table_name = :talentlms_completed_trainings

    belongs_to :login
    belongs_to :config
  end
end
