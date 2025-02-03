class Filters::Criteria::EnrollmentDate < Filters::Criteria::Base
  LEVEL = :project

  attribute :date_range, :range

  def apply(scope)
    scope.open_between(start_date: date_range.begin, end_date: date_range.end)
  end
end
