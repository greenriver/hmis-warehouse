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
    [
      'Admin',
      'Reports Dashboard Read',
    ].freeze
  end
end
