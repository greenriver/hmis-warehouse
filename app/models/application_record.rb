###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ApplicationRecord < ActiveRecord::Base
  include Efind
  include ArelHelper
  self.abstract_class = true

  def self.original_config
    original_config = {
      'db' => ['db'],
      'db/migrate' => ['db/migrate'],
      'db/seeds' => ['db/seeds'],
      'config/database' => ['config/database.yml'],
    }
  end

  def self.setup_config
    new_config = original_config
    # set config variables for custom database
    new_config.each do |path, value|
      Rails.application.config.paths[path] = value
    end
    db_config = Rails.application.config.paths['config/database'].to_a.first
    ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]
  end
end
