###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranConfirmation
  class Credential < ::GrdaWarehouse::RemoteCredential
    alias_attribute :apikey, :password
  end
end
