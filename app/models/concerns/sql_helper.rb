###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Module for SQL-related helper methods. Assumes a PostgreSQL database.
# Perhaps there's a way to do this with the active_record_extended gem but I couldn't find it
module SqlHelper
  extend ActiveSupport::Concern

  # Quotes an array of elements for use in SQL queries.
  #
  # @param array [Array] The array of elements to be quoted.
  # @param type [String, nil] The SQL type of the array (e.g., 'integer', 'text').
  #   If nil, the method returns the array without type casting.
  #
  # @return [String] A string representing the quoted SQL array.
  #
  # @raise [ArgumentError] If an element in the array is not a String, Symbol, or Integer.
  #
  # @example
  #   SqlHelper.quote_sql_array(['foo', 'bar'], type: 'text')
  #   # => "'{\"foo\",\"bar\"}'::text[]"
  #
  module_function def quote_sql_array(array, type:)
    connection = ActiveRecord::Base.connection
    quoted_elements = array.map do |element|
      case element.presence
      when String, Symbol
        "\"#{connection.quote_string(element.to_s)}\""
      when Integer
        element.to_s
      else
        raise ArgumentError, "Invalid element type: #{element.class}"
      end
    end
    result = "'{#{quoted_elements.join(',')}}'"
    type ? "#{result}::#{type}[]" : result
  end

  # Generates a SQL condition to check if a field is a non-empty subset of a given set.
  #
  # @param field [String] The name of the database field to check.
  # @param set [Array] The set to compare against.
  # @param type [String] The SQL type of the array (e.g., 'integer', 'text').
  #
  # @return [String] A SQL condition string.
  #
  # @example
  #   SqlHelper.non_empty_array_subset_condition(field: 'tags', set: ['ruby', 'rails'], type: 'text')
  #   # => "tags <@ '{\"ruby\",\"rails\"}'::text[] AND tags != '{}'::text[]"
  module_function def non_empty_array_subset_condition(field:, set:, type:)
    empty_q_set = SqlHelper.quote_sql_array([], type: type)
    q_set = SqlHelper.quote_sql_array(set, type: type)
    "#{field} <@ #{q_set} AND #{field} != #{empty_q_set}"
  end
end
