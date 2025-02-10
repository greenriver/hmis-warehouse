class Filters::Criteria::FilterForPshMoveIn< Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.psh_move_in

  def apply(scope)
    scope.in_project_type(3).where(move_in_date: input.range)
  end
end
