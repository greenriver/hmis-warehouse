###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'uri'
require 'net/http'
module GrdaWarehouse
  class RemoteCredentials::S3 < GrdaWarehouse::RemoteCredential
    alias_attribute :s3_access_key_id, :username
    alias_attribute :s3_secret_access_key, :password
  end
end
