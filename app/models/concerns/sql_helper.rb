###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Module for SQL-related helper methods. Assumes a PostgreSQL database.
# Perhaps there's a way to do this with the active_record_extended gem but I couldn't find it
module SqlHelper
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
    type = type&.to_s
    raise ArgumentError, "Invalid type: '#{type}'" unless type.in?([nil, 'integer', 'text', 'varchar'])
    raise ArgumentError, 'Array argument required' unless array.is_a?(Array)

    connection = ActiveRecord::Base.connection
    quoted_elements = array.map do |element|
      element = element.presence
      case element
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

  # Generates a SQL condition to check if a field contains ONLY values from a given set (and is non-empty).
  # Uses PostgreSQL's <@ (contained-by/subset) operator.
  #
  # IMPORTANT: This checks that ALL elements in the field are in the set. If the field has ANY elements
  # not in the set, this will return false. For checking if the field has ANY elements from the set,
  # use `array_overlap_condition` instead.
  #
  # @param field [String] The name of the database field to check.
  # @param set [Array] The set to compare against.
  # @param type [String] The SQL type of the array (e.g., 'integer', 'text').
  #
  # @return [String] A SQL condition string.
  #
  # @example Use this when you want EXCLUSIVE matching (field contains ONLY these values)
  #   # Field has ['ruby', 'rails'] -> TRUE
  #   # Field has ['ruby'] -> TRUE
  #   # Field has ['ruby', 'python'] -> FALSE (python not in set)
  #   SqlHelper.non_empty_array_subset_condition(field: 'tags', set: ['ruby', 'rails'], type: 'text')
  #   # => "tags <@ '{\"ruby\",\"rails\"}'::text[] AND tags != '{}'::text[]"
  #
  # @example For checking if field has ANY of these values, use array_overlap_condition instead
  #   # Field has ['ruby', 'python'] with set ['ruby', 'rails'] -> TRUE (has ruby)
  #   SqlHelper.array_overlap_condition(field: 'tags', set: ['ruby', 'rails'], type: 'text')
  module_function def non_empty_array_subset_condition(field:, set:, type:)
    empty_q_set = SqlHelper.quote_sql_array([], type: type)
    q_set = SqlHelper.quote_sql_array(set, type: type)
    "#{field} <@ #{q_set} AND #{field} != #{empty_q_set}"
  end

  # Generates a SQL condition to check if a field has ANY overlap with a given set.
  # Uses PostgreSQL's && (overlap) operator to check for array intersection.
  #
  # This checks if the field contains AT LEAST ONE element from the set. The field can also
  # contain other elements not in the set.
  #
  # @param field [String] The name of the database field to check.
  # @param set [Array] The set to compare against.
  # @param type [String] The SQL type of the array (e.g., 'integer', 'text', 'varchar').
  #
  # @return [String] A SQL condition string.
  #
  # @example Use this when you want to find records with ANY of these values
  #   # Field has ['ruby', 'python'] -> TRUE (has ruby)
  #   # Field has ['rails'] -> TRUE (has rails)
  #   # Field has ['python', 'java'] -> FALSE (no overlap)
  #   SqlHelper.array_overlap_condition(field: 'tags', set: ['ruby', 'rails'], type: 'text')
  #   # => "tags && '{\"ruby\",\"rails\"}'::text[]"
  module_function def array_overlap_condition(field:, set:, type:)
    q_set = SqlHelper.quote_sql_array(set, type: type)
    "#{field} && #{q_set}"
  end
end
