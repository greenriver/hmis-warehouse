# Rails.logger.debug "Running initializer in #{__FILE__}"

# save health database settings in global var
DB_WAREHOUSE ||= YAML::load(ERB.new(File.read(Rails.root.join("config","database.yml"))).result)[Rails.env]['warehouse']
