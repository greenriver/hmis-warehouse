###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Only the JWT path consumes the IdP service registry.
if AuthMethod.jwt?
  # to_prepare ensures autoloaded classes are available and survives dev reloads.
  Rails.application.config.to_prepare do
    Idp::ServiceFactory.register_idp_service('keycloak', Idp::KeycloakService)
  end
end
