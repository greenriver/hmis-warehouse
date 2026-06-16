###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health::Soap
  class Config < HealthBase
    self.table_name = :soap_configs

    attr_encrypted :pass, key: ENV['ENCRYPTION_KEY'][0..31]
  end
end
