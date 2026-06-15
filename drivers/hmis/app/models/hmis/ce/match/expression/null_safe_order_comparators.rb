# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  # Order comparators raise when either operand is NULL. For CE match rules, missing
  # data should mean the rule does not match (false), not a runtime error.
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
