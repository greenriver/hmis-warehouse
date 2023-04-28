
###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ClientViewCredential < ::GrdaWarehouse::RemoteCredential
    include GrdaWarehouse::RemoteCredentials::Oauth

    alias_attribute :link_base, :endpoint
  end
end
