module SqlHelper
  extend ActiveSupport::Concern
  def quote_sql_array(array)
    quoted_elements = array.map do |element|
      case element.presence
      when String, Symbol
        "\"#{element}\""
      when Integer
        element.to_s
      else
        raise "invalid element #{element}"
      end
    end
    "{#{quoted_elements.join(',')}}"
  end
  module_function :quote_sql_array
end
