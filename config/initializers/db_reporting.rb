# save health database settings in global var
DB_REPORTING = YAML::load(ERB.new(File.read(Rails.root.join("config","database_reporting.yml"))).result)[Rails.env]
