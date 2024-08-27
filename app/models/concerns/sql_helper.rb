module SqlHelper
  extend ActiveSupport::Concern

  module_function def quote_sql_array(array)
    quoted_elements = array.map do |element|
      case element.presence
      when String, Symbol
        ActiveRecord::Base.connection.quote(element.to_s)
      when Integer
        element.to_s
      when NilClass
        'NULL'
      else
        raise ArgumentError, "Invalid element type: #{element.class}"
      end
    end
    "{#{quoted_elements.join(',')}}"
  end
  module_function :quote_sql_array
end
