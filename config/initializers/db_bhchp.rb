# save bhchp database settings in global var
DB_BHCHP = YAML::load(ERB.new(File.read(Rails.root.join("config","database_bhchp.yml"))).result)[Rails.env]
