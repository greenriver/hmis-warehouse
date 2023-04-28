###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module RemoteCredentials::Oauth
    extend ActiveSupport::Concern

    included do
      alias_attribute :client_id, :username
      alias_attribute :client_secret, :encrypted_password
      alias_attribute :token_url, :path
      alias_attribute :base_url, :endpoint
      alias_attribute :oauth_scope, :bucket
    end
  end
end
