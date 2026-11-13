###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Resolves the HMIS data source for the request from its host. Included by Hmis::BaseController
# and by the Devise Hmis::SessionsController, which does not inherit from BaseController.
module Hmis::Concerns::RequestDataSource
  extend ActiveSupport::Concern

  private

  # HMIS domain for this request; used to resolve the data source (DataSource.hmis).
  # @see docs/features/hmis/multi-hmis-support.md
  def current_hmis_host
    # In development, use untrusted header X-Hmis-Dev-Host.
    # Trusted header 'request.host' cannot be used because the dev server setup makes it appear to come from the backend host.
    return request.headers['X-Hmis-Dev-Host'].presence || raise('X-Hmis-Dev-Host header required in development') if Rails.env.development?

    # Trust Rack/Rails host resolution (respects trusted proxies and allowed hosts)
    return request.host if request.host.present?

    raise 'cannot determine HMIS host'
  end

  def current_data_source
    @current_data_source ||= begin
      data_source = GrdaWarehouse::DataSource.hmis.find_by(hmis: current_hmis_host)
      raise "HMIS data source not configured: #{current_hmis_host}" unless data_source.present?

      data_source
    end
  end
end
