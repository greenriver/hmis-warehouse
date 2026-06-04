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
    superset_base_url
  end

  def self.available?
    password_set = ENV['SUPERSET_ADMIN_PASS'].present?
    return password_set if Rails.env.development?

    password_set && ENV['SUPERSET_ADMIN_PASS'] != 'admin'
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
