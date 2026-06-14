###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# to_prepare ensures autoloaded classes are available and survives dev reloads.
Rails.application.config.to_prepare do
  Idp::ServiceFactory.register_idp_service('keycloak', Idp::KeycloakService)
end
