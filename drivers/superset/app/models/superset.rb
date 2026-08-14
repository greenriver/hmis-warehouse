###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Superset
  def self.table_name_prefix
    'superset_'
  end

  def self.superset_base_url
    fqdn = ENV.fetch('FQDN', 'warehouse.openpath.host')
    tokens = fqdn.split('.')
    tokens = [tokens[0], 'superset', tokens[1..]].flatten
    'https://' + ENV.fetch('SUPERSET_FQDN', tokens.join('.'))
  end

  def self.warehouse_login_url(user = nil)
    if AuthMethod.jwt?
      base_url = superset_base_url
      connector_id = user&.last_connector_id
      return base_url if connector_id.blank?

      # Superset's own oauth2-proxy sidecar only forwards connector_id to Dex when the
      # request hits its /oauth2/sign_in endpoint (per its loginURLParameters config) --
      # not when it's just appended to the app URL. Without this, Dex shows its connector
      # picker instead of sending the user straight to their IdP.
      base_url + Idp::Oauth2ProxySignInPath.call(connector_id: connector_id, redirect_to: '/')
    else
      "#{superset_base_url}/login/The%20Warehouse"
    end
  end

  # The value SUPERSET_ADMIN_PASS is seeded with in the local/dev images. Outside development a
  # password still set to this placeholder means Superset was never really configured, so we treat
  # it as unavailable rather than exposing it with the insecure default.
  INSECURE_DEFAULT_ADMIN_PASS = 'admin'

  def self.available?
    AuthMethod.jwt? ? admin_password_configured? : doorkeeper_app_registered?
  end

  # Under JWT, Superset rides the shared admin credential (see Superset::Api), so it's usable only
  # once that credential is really set: any non-blank value in development, and anything other than
  # the insecure placeholder everywhere else.
  def self.admin_password_configured?
    password = ENV['SUPERSET_ADMIN_PASS']
    return false if password.blank?
    return true if Rails.env.development?

    password != INSECURE_DEFAULT_ADMIN_PASS
  end

  # Under Devise, availability means a Doorkeeper OAuth app is registered for the Superset host.
  def self.doorkeeper_app_registered?
    a_t = Doorkeeper::Application.arel_table
    Doorkeeper::Application.where(a_t[:redirect_uri].matches("%#{superset_base_url}%")).exists?
  end

  def self.available_to_user?(user)
    available? && GrdaWarehouse::WarehouseReports::ReportDefinition.viewable_by(user).where(url: 'superset/warehouse_reports/reports').exists?
  end

  # NOTE: this needs to be kept in sync with
  # https://github.com/greenriver/superset-sync/blob/main/docker/superset/superset_config.py
  def self.available_superset_roles
    api = Superset::Api.new
    return default_roles unless api.available?

    begin
      roles = api.roles['result']&.map { |role| role['name'] } || []
      roles.reject! { |role| ignored_roles.include?(role) }
      roles.presence || default_roles
    rescue Curl::Err::HostResolutionError, JSON::ParserError => e
      UnifiedErrorReporter.call(e, "Error fetching Superset roles: #{e.message}, using default roles")
      default_roles
    end
  end

  def self.default_roles
    [
      'Green River Admin',
      'Warehouse Admin',
      'Report Creator',
      'Report Runner',
    ].freeze
  end

  def self.ignored_roles
    [
      'Admin',
      'Public',
      'Alpha',
      'Gamma',
      'sql_lab',
      'granter',
    ].freeze
  end
end
