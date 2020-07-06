class NormalizedIntegerArrayType < ActiveRecord::Type::String

  def cast(value)
    if value != nil
      Array.wrap(value).map { |v| v.presence&.to_i }.compact
    end
  end

end
