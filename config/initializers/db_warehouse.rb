# save health database settings in global var
DB_WAREHOUSE = YAML::load(ERB.new(File.read(Rails.root.join("config","database_warehouse.yml"))).result)[Rails.env]
