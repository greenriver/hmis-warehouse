class NormalizedSymbolArrayType < ActiveRecord::Type::String

  def cast(value)
    if value != nil
      Array.wrap(value).map { |v| v.presence&.to_sym }.compact
    end
  end

end
