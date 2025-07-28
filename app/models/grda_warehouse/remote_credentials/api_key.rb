# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
