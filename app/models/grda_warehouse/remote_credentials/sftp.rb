###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RemoteCredentials::Sftp < GrdaWarehouse::RemoteCredential
    alias_attribute :host, :endpoint
    alias_attribute :private_key, :region
  end
end
