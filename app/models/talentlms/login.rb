###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Talentlms
  class Login < GrdaWarehouseBase
    self.table_name = :talentlms_logins

    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]
    belongs_to :user
  end
end
