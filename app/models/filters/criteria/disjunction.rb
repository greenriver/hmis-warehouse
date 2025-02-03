# An "OR chain" of filters
class Filters::Criteria::Disjunction < Filters::Criteria::Base
  attribute :filters, :array

  def apply(scope)
    return scope if filters.empty?
    return filters.first.apply(scope) if filters.one?

    filtered_scope = filters.map { |filter| filter.apply(scope) }.reduce { |a, b| a.or(b) }
    scope.where(id: filtered_scope.select(:id))
  end
end
