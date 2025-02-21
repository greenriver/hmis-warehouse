class Filters::Criteria::FilterForFirstTimeHomelessInPastTwoYears < Filters::Criteria::Base
  def applies? = input.first_time_homeless

  def apply(scope)
    visible_enrollments = scope.joins(:project).merge(viewable_project_scope)

    # Homeless enrollments open the two years prior to the report start
    recent_homeless_enrollments = visible_enrollments.
      homeless.
      open_between(start_date: input.start - 2.years, end_date: input.start)
    # For a given client, only include rows where they don't have an open homeless
    # enrollment in the 2 years prior to the report start date
    scope.homeless.where.not(client_id: recent_homeless_enrollments.select(:client_id))
  end
end
