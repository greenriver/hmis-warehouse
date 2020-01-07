###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Soap
  class Config < HealthBase
    self.table_name = :soap_configs

    attr_encrypted :pass, key: ENV['ENCRYPTION_KEY']
  end
end