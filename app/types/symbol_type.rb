class SymbolType < ActiveRecord::Type::String

  def cast(value)
    value.presence&.to_sym
  end

end
