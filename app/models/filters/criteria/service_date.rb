class Filters::Criteria::ServiceDate < Filters::Criteria::Base
  LEVEL = :project

  attribute :date_range, :range

  def apply(scope)
    scope.with_service_between(start_date: date_range.begin, end_date: date_range.end)
  end
end
