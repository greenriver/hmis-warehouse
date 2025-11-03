###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern providing IDP (Identity Provider) support methods for User model.
#
# Provides methods to check IDP capabilities and access IDP services.
# Designed to be extensible - adding new IDPs only requires registering
# them in Idp::ServiceFactory.
module IdpSupport
  extend ActiveSupport::Concern

  included do
    # Check if user's IDP supports user management operations.
    #
    # @return [Boolean] true if IDP supports creating/updating users
    def idp_supports_user_management?
      idp_service.supports_user_management?
    end

    # Check if user's IDP supports profile field updates (name, email, phone).
    #
    # @return [Boolean] true if IDP supports updating profile fields
    def idp_supports_profile_updates?
      idp_service.supports_profile_updates?
    end

    # Check if user's IDP supports sending user invitations.
    #
    # @return [Boolean] true if IDP supports invitations
    def idp_supports_invitations?
      idp_service.supports_invitations?
    end

    # Get appropriate IDP service for user's primary IDP.
    #
    # @return [Idp::Service] Instance of the appropriate IDP service
    def idp_service
      Idp::ServiceFactory.for_connector(primary_idp)
    end

    # Get primary IDP connector ID.
    #
    # Returns last_connector_id if set, otherwise the first enabled connector_id.
    #
    # @return [String, nil] Connector ID or nil if no IDP connected
    def primary_idp
      last_connector_id.presence || enabled_authentication_sources.first&.connector_id
    end

    # Convenience method checking if primary IDP is Zitadel.
    #
    # @return [Boolean] true if primary IDP is Zitadel
    def zitadel_idp?
      primary_idp == 'zitadel'
    end
  end
end
