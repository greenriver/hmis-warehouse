###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RemoteCredentials::Oauth < GrdaWarehouse::RemoteCredential
    alias_attribute :client_id, :username
    alias_attribute :client_secret, :encrypted_password
    alias_attribute :token_url, :path
    alias_attribute :base_url, :endpoint
    alias_attribute :oauth_scope, :bucket
    alias_attribute :json_other_values, :region

    def other_values= hash
      self.json_other_values = hash.to_json
    end

    def other_values(key = nil)
      @other_values ||= JSON.parse(json_other_values)
      key.nil? ? @other_values : @other_values[key]
    rescue JSON::ParserError, TypeError
      nil
    end
  end
end
