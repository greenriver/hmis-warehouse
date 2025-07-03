###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  def self.warehouse_login_url
    "#{superset_base_url}/login/The%20Warehouse"
  end

  def self.available?
    a_t = Doorkeeper::Application.arel_table
    Doorkeeper::Application.where(a_t[:redirect_uri].matches("%#{superset_base_url}%")).exists?
  end

  # NOTE: this needs to be kept in sync with
  # https://github.com/greenriver/superset-sync/blob/main/docker/superset/superset_config.py
  def self.available_superset_roles
    begin
      roles = Superset::Api.new.roles['result'].map { |role| role['name'] }
      roles.reject! { |role| ignored_roles.include?(role) }
      return roles if Superset::Api.new.available?
    rescue Curl::Err::HostResolutionError => e
      Rails.logger.error("Error fetching Superset roles: #{e.message}, using default roles")
    end
    # Fallback to the default roles if the API is not available
    default_roles
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
      'Public',
      'Alpha',
      'Gamma',
      'sql_lab',
      'granter',
    ].freeze
  end
end
