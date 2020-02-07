###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###
#
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.original_config
    original_config = {
      env_schema: nil,
      'db' => ['db'],
      'db/migrate' => ['db/migrate'],
      'db/seeds' => ['db/seeds'],
      'config/database' => ['config/database.yml'],
    }
  end

  def self.setup_config
    new_config = original_config
    ENV['SCHEMA'] = 'db/reporting/schema.rb'
    # set config variables for custom database
    new_config.each do |path, value|
      Rails.application.config.paths[path] = value
    end
    db_config = Rails.application.config.paths['config/database'].to_a.first
    ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]
  end
end