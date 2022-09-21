###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranConfirmation
  class VaCheckHistory < GrdaWarehouseBase
    self.table_name = :va_check_histories

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    scope :recent, -> { order(check_date: :desc).limit(1) }
  end
end
