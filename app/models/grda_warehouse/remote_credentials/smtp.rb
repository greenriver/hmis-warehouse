###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'uri'
require 'net/http'
module GrdaWarehouse
  class RemoteCredentials::Smtp < GrdaWarehouse::RemoteCredential
    alias_attribute :server, :endpoint
    alias_attribute :from, :path
  end
end
