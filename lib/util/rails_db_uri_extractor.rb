module RailsDbUriExtractor
  def self.extract_uri(name:, env:)
    YAML.safe_load(ERB.new(File.read(Rails.root.join('config/database.yml'))).result, aliases: true).yield_self do |config|
      db_config = config.dig(env, name)
      URI::Generic.build(
        scheme: db_config['adapter'],
        userinfo: db_config.values_at('username', 'password').join(':'),
        host: db_config['host'],
        port: db_config['port'],
        path: "/#{db_config['database']}",
      ).to_s
    end
  end
end
