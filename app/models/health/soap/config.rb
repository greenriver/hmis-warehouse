###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Soap
  class Config < HealthBase
    self.table_name = :soap_configs

    attr_encrypted :pass, key: ENV['ENCRYPTION_KEY'][0..31]
  end
end
