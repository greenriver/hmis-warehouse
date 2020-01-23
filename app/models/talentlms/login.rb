###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Talentlms
  class Login < GrdaWarehouseBase
    self.table_name = :talentlms_logins

    attr_encrypted :password, key: ENV['ENCRYPTION_KEY']
    belongs_to :user
  end
end