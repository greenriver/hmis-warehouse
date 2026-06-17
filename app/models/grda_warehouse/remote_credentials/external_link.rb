###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class RemoteCredentials::ExternalLink < GrdaWarehouse::RemoteCredential
    alias_attribute :link_base, :endpoint
  end
end
