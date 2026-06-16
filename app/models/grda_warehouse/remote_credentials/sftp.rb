###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class RemoteCredentials::Sftp < GrdaWarehouse::RemoteCredential
    alias_attribute :host, :endpoint
    alias_attribute :private_key, :region
    alias_attribute :port, :bucket
  end
end
