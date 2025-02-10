class Filters::Criteria::FilterForHouseholdType < Filters::Criteria::Base
  LEVEL = :client

  def applies?
    input.household_type.present? && input.household_type != :all
  end

  def apply(scope)
    case input.household_type
    when :without_children
      scope.adult_only_households
    when :with_children
      scope.adults_with_children
    when :only_children
      scope.child_only_households
    else
      raise
    end
  end
end
