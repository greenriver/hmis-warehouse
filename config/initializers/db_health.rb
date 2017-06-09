# save health database settings in global var
DB_HEALTH = YAML::load(ERB.new(File.read(Rails.root.join("config","database_health.yml"))).result)[Rails.env]
