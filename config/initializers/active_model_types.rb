module ActiveModelTypes
  class RangeType < ActiveModel::Type::Value
    def cast(value)
      case value
      when Range
        value
      else
        raise ArgumentError, "#{value.inspect} is not valid"
      end
    end
  end

  class ArrayType < ActiveModel::Type::Value
    def cast(value)
      case value
      when Array
        value
      else
        raise ArgumentError, "#{value.inspect} is not valid"
      end
    end
  end

  class SymbolType < ActiveModel::Type::Value
    def cast(value)
      case value
      when Symbol, String
        value.to_sym
      else
        raise ArgumentError, "#{value.inspect} is not valid"
      end
    end
  end
end

ActiveModel::Type.register(:range, ActiveModelTypes::RangeType)
ActiveModel::Type.register(:array, ActiveModelTypes::ArrayType)
ActiveModel::Type.register(:symbol, ActiveModelTypes::SymbolType)
