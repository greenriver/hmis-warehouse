# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  class Validator
    MAX_LENGTH = 2_000

    def self.call(expression)
      new.call(expression)
    end

    def call(expression)
      errors = HmisErrors::Errors.new

      if expression.blank?
        errors.add(:expression, :required)
        return errors
      end

      if expression.length > MAX_LENGTH
        errors.add(:expression, :invalid, message: "is too long (maximum is #{MAX_LENGTH} characters)")
        return errors
      end

      calculator = CalculatorFactory.build
      begin
        calculator.ast(expression.strip)
      rescue Dentaku::ParseError, Dentaku::TokenizerError => e
        errors.add(:expression, :invalid, message: e.message)
        return errors
      end

      validate_identifiers!(expression, calculator, errors)

      errors
    end

    private

    def validate_identifiers!(expression, calculator, errors)
      field_map = FieldMap.new

      calculator.dependencies(expression).each do |field|
        # Pass Client.none scope since we don't actually need to query any client values here,
        # we just want to check for any raised errors to validate the field
        field_map.client_query(GrdaWarehouse::Hud::Client.none, field)
      rescue ArgumentError => e
        errors.add(:expression, :invalid, message: e.message)
      end
    end
  end
end
