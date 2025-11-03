###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Represents a user's connection to an Identity Provider (IDP).
#
# Users can be connected to multiple IDPs. This model tracks each connection,
# including the connector_id (IDP identifier) and connector_user_id (user's ID within that IDP).
class UserAuthenticationSource < ApplicationRecord
  acts_as_paranoid

  belongs_to :user

  validates :connector_id, presence: true
  validates :connector_user_id, presence: true
  validates :connector_id, uniqueness: { scope: [:connector_user_id], conditions: -> { where(deleted_at: nil) } }

  scope :enabled, -> { where(enabled: true) }

  # Return human-readable IDP name.
  #
  # @return [String] IDP name (e.g., "Zitadel", "Okta")
  def idp_name
    idp_service.idp_name
  end

  # Get IDP service instance for this connector.
  #
  # @return [Idp::Service] Instance of the appropriate IDP service
  def idp_service
    Idp::ServiceFactory.for_connector(connector_id)
  end
end
