###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::AdHocClient < GrdaWarehouseBase
  acts_as_paranoid

  belongs_to :ad_hoc_data_source
  belongs_to :ad_hoc_batch, foreign_key: :batch_id
end
