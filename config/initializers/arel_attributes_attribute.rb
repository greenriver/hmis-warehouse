###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Rails.logger.debug "Running initializer in #{__FILE__}"

# FIXME: should not be monkey patching Arel
module ArelExtensions
  module Attribute
    def to_sql
      table = relation.instance_variable_get(:@klass)
      connection = table.connection
      table_name = connection.quote_table_name table.table_name
      column_name = connection.quote_column_name name
      "#{table_name}.#{column_name}"
    end
  end
end
Arel::Attributes::Attribute.include ArelExtensions::Attribute
