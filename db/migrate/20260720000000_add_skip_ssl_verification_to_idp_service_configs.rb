###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Allows an IDP config to opt out of TLS certificate verification, for
# non-production instances that use self-signed certificates.
class AddSkipSslVerificationToIdpServiceConfigs < ActiveRecord::Migration[7.2]
  def change
    add_column :idp_service_configs, :skip_ssl_verification, :boolean, default: false, null: false
  end
end
