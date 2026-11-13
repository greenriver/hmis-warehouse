# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  # Dentaku order comparators (>, >=, <, <=) raise on `evaluate!`when either operand is NULL.
  # For CE match rules, missing data should mean the rule does not match (false), not a runtime error.
  #
  # Prepended onto Dentaku's four order-comparator AST classes at load time.
  # Equality (=, !=) is unchanged.
  #
  # Examples when score is NULL:
  #   score >= 8                              => false (was: Dentaku::ArgumentError)
  #   score >= 8 OR veteran_status = 1        => true if veteran_status = 1 (was: Dentaku::ArgumentError)
  #   score != NULL AND score >= 8            => false (explicit guard unchanged)
  module NullSafeOrderComparators
    ORDER_COMPARATOR_CLASSES = [
      Dentaku::AST::GreaterThan,
      Dentaku::AST::GreaterThanOrEqual,
      Dentaku::AST::LessThan,
      Dentaku::AST::LessThanOrEqual,
    ].freeze

    def value(context = {})
      l = left.value(context)
      r = right.value(context)
      return false if l.nil? || r.nil?

      super
    end
  end
end

Hmis::Ce::Match::Expression::NullSafeOrderComparators::ORDER_COMPARATOR_CLASSES.each do |klass|
  klass.prepend(Hmis::Ce::Match::Expression::NullSafeOrderComparators) unless klass < Hmis::Ce::Match::Expression::NullSafeOrderComparators
end
