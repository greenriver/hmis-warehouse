###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ApplicationRecord < ActiveRecord::Base
  include Efind
  include ArelHelper
  self.abstract_class = true
  self.filter_attributes = Rails.application.config.filter_parameters

  connects_to database: { writing: :primary, reading: :primary }

  def self.needs_migration?
    ActiveRecord::Migration.check_pending!
  end

  def self.replace_scope(name, body, &block)
    singleton_class.undef_method name
    scope name, body, &block
  end
end
