###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Register IDP services with the factory
# Using to_prepare ensures all models are loaded before registration
Rails.application.config.to_prepare do
  Idp::ServiceFactory.register_idp_service('zitadel', Idp::ZitadelService)
  Idp::ServiceFactory.register_idp_service('keycloak', Idp::KeycloakService)
end
