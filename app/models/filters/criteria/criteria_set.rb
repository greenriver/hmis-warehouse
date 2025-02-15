# enumerable wrapper for criteria set
#
class Filters::Criteria::CriteriaSet
  include Enumerable

  def initialize(criteria)
    @criteria = Array(criteria)
  end

  def each(&block)
    @criteria.each(&block)
  end

  # Returns a new CriteriaSet with filtered criteria (this is array filter)
  def filter(&block)
    CriteriaSet.new(@criteria.filter(&block))
  end

  # Class method to apply criteria to an arel scope
  def apply(scope)
    reduce(scope) do |result, criterion|
      criterion.apply(result)
    end
  end
end
