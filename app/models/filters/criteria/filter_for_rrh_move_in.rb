class Filters::Criteria::FilterForRrhMoveIn < Filters::Criteria::Base
  def applies? = input.rrh_move_in

  def apply(scope)
    scope.in_project_type(13).where(move_in_date: input.range)
  end
end
