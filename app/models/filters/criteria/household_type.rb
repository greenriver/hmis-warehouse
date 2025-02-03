class Filters::Criteria::HouseholdType < Filters::Criteria::Base
  LEVEL = :client

  attribute :household_type, :symbol

  def apply(scope)
    case household_type
    when :without_children
      scope.adult_only_households
    when :with_children
      scope.adults_with_children
    when :only_children
      scope.child_only_households
    end
  end
end
