DB_REPORTING = YAML::load(ERB.new(File.read(Rails.root.join("config","database.yml"))).result)[Rails.env]['reporting']
