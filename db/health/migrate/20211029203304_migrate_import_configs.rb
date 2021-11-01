class MigrateImportConfigs < ActiveRecord::Migration[5.2]
  def change
    configs = YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
    configs.each do |name, config|
      Health::ImportConfig.create(
        name: name,
        host: config['host'],
        path: config['path'],
        username: config['username'],
        password: config['password'],
        destination: config['destination'],
        data_source_name: config['data_source_name'],
      ) if config['username'].present?
    end
  end
end
