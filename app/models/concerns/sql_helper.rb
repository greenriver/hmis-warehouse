module SqlHelper
  extend ActiveSupport::Concern

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

  module_function def non_empty_array_subset_condition(field:, set:, type:)
    empty_q_set = SqlHelper.quote_sql_array([], type: type)
    q_set = SqlHelper.quote_sql_array(set, type: type)
    "#{field} <@ #{q_set} AND #{field} != #{empty_q_set}"
  end
end
