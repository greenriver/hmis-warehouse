###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

  # Determine whether the given search term is possibly a Primary Key (it's numeric and less than 4 bytes)
  def self.possibly_pk?(search_term) # could add optional arg for 4 byte vs 8 byte, if needed later
    numeric = /[\d-]+/.match(search_term).try(:[], 0) == search_term
    return false unless numeric

    max_pk = 2_147_483_648 # PK is a 4 byte signed INT (2 ** ((4 * 8) - 1))
    search_term.to_i < max_pk
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
