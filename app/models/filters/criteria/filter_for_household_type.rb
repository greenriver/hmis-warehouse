# frozen_string_literal: true

class Filters::Criteria::FilterForHouseholdType < Filters::Criteria::Base
  def applies?
    household_type.present?
  end

  def apply(scope)
    scope = super(scope)
    case household_type
    when :without_children
      scope.adult_only_households
    when :with_children
      scope.adults_with_children
    when :only_children
      scope.child_only_households
    else
      raise "unknown household_type \"#{household_type}\""
    end
  end

  def household_type
    return nil unless input.household_type.present?

    type_as_sym = input.household_type.to_sym
    type_as_sym == :all ? nil : type_as_sym
  end
end
