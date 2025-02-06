###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ApplicationRecord < ActiveRecord::Base
  include Efind
  include ArelHelper
  self.abstract_class = true
  self.filter_attributes = Rails.application.config.filter_parameters

  connects_to database: { writing: :primary, reading: :primary }

  def self.find_safely(tainted_id)
    safe_id = begin
      Integer(tainted_id)
    rescue ArgumentError, TypeError
      nil
    end
    raise(ActiveRecord::RecordNotFound, "#{sti_name} Record not found for ID: #{tainted_id}") unless safe_id

    find(safe_id)
  end

  def self.needs_migration?
    ActiveRecord::Migration.check_pending!
  end

  def self.replace_scope(name, body, &block)
    singleton_class.undef_method name
    scope name, body, &block
  end

  def self.vacuum_table(full_with_lock: false)
    opts = 'FULL' if full_with_lock
    connection.exec_query("VACUUM #{opts} #{connection.quote_table_name(table_name)}")
  end
end
