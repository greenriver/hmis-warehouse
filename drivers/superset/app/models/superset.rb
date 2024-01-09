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

  def self.available?
    a_t = Doorkeeper::Application.arel_table
    Doorkeeper::Application.where(a_t[:redirect_uri].matches("%#{superset_base_url}%")).exists?
  end
end
