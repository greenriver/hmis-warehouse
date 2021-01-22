###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportingBase < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :reporting, reading: :reporting }

  # def self.setup_config
  #   new_config = {
  #     'db' => ['db/reporting'],
  #     'db/migrate' => ['db/reporting/migrate'],
  #     'db/seeds' => ['db/reporting/seeds'],
  #     'config/database' => ['config/database_reporting.yml'],
  #   }
  #   ENV['SCHEMA'] = 'db/reporting/schema.rb'
  #   # set config variables for custom database
  #   new_config.each do |path, value|
  #     Rails.application.config.paths[path] = value
  #   end
  #   db_config = Rails.application.config.paths['config/database'].to_a.first
  #   ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]
  # end

  def self.needs_migration?
    ActiveRecord::MigrationContext.new('db/reporting/migrate', Reporting::SchemaMigration).needs_migration?
  end
end
