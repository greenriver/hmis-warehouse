###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'uri'
require 'net/http'
module GrdaWarehouse
  class RemoteCredentials::Smtp < GrdaWarehouse::RemoteCredential
    alias_attribute :server, :endpoint
    alias_attribute :from, :path
  end
end
