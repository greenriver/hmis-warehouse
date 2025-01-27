
module Filters::Components
  HouseholdTypeFilter = Struct.new(:label, :household_type, keyword_init: true) do
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

    def self.all
      raise
    end
  end
end
