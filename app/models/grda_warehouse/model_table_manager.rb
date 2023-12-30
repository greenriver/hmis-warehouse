###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Utility to assist with table resets during testing
class GrdaWarehouse::ModelTableManager
  attr_accessor :model
  def initialize(model)
    raise 'not allowed in production' if Rails.env.production?

    self.model = model
  end

  def next_pk_sequence=(value)
    # puts "setting next pk for #{model.name} to #{value}"
    execute "ALTER SEQUENCE #{quote_table_name(sequence_name)} RESTART WITH #{quote(value)}"
  end

  def truncate_table(modifier:)
    # puts "truncating table for #{model.name}"
    execute("TRUNCATE TABLE #{quote_table_name(table_name)} RESTART IDENTITY #{modifier}")
  end

  protected

  def sequence_name
    q_table_name = quote_table_name(table_name) # double quote "'table_name'"
    select_value "SELECT pg_get_serial_sequence(#{quote(q_table_name)}, #{quote(primary_key)})"
  end

  delegate :connection, :table_name, :primary_key, to: :model
  delegate :select_value, :execute, :quote, :quote_table_name, to: :connection
end
