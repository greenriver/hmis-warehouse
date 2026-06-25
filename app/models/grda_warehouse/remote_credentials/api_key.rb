###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class RemoteCredentials::ApiKey < GrdaWarehouse::RemoteCredential
    alias_attribute :base_url, :endpoint

    # Can't use alias_attribute here due to RemoteCredential's use of attr_encrypted(:password)
    def authorization_header = password

    def authorization_header=(value)
      self.password = value
    end
  end
end
