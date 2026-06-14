###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Splits the two jobs connector_id was doing into separate columns so we can
# cleanly support multiple realms/tenants per provider:
#
#   provider     — the registered IDP type (e.g. 'keycloak'); selects the
#                  service class. One per integration.
#   connector_id — the routing key from the auth proxy (the JWT's
#                  federated_claims.connector_id / Dex connector name). One per
#                  realm/tenant, so two Keycloak realms become two configs with
#                  the same provider and distinct connector_ids. Stays uniquely
#                  constrained (the existing partial unique index).
class DecoupleProviderFromConnectorIdOnIdpServiceConfigs < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      add_column :idp_service_configs, :provider, :string

      # Until now connector_id *was* the provider type, so it's the correct seed.
      execute("UPDATE idp_service_configs SET provider = connector_id WHERE provider IS NULL")

      change_column_null :idp_service_configs, :provider, false
    end
  end

  def down
    remove_column :idp_service_configs, :provider
  end
end
