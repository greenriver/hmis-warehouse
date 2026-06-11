###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module IdpSupport
  extend ActiveSupport::Concern

  def idp_supports_user_management?
    idp_service.supports_user_management?
  end

  def idp_supports_profile_updates?
    idp_service.supports_profile_updates?
  end

  def idp_service
    return Idp::ServiceFactory.for_connector(primary_idp) if primary_idp

    Idp::NullService.new
  end

  def primary_idp
    last_connector_id.presence || user_authentication_sources.order(:created_at).first&.connector_id
  end

  def email_change_enabled?
    idp_supports_profile_updates?
  end
end
