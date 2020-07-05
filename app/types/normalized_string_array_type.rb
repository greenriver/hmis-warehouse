class NormalizedStringArrayType < ActiveRecord::Type::String

  def cast(value)
    if value != nil
      Array.wrap(value).map { |v| v.to_s.presence }.compact
    end
  end

end
