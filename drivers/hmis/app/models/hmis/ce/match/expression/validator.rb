# frozen_string_literal: true

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

      stripped = expression.strip
      calculator = CalculatorFactory.build
      begin
        calculator.ast(stripped)
      rescue Dentaku::Error => e
        errors.add(:expression, :invalid, message: e.message)
        return errors
      end

      validate_identifiers(stripped, calculator, errors)

      errors
    end

    private

    # Verify each field reference resolves to a known namespace + key.
    # field_map.client_query raises ArgumentError on an unknown client field, unknown
    # CDE entity, or unknown CDE key. Client.none short-circuits the registered query
    # callbacks so we only pay for the registry lookup, not for executing them.
    def validate_identifiers(expression, calculator, errors)
      field_map = FieldMap.new

      calculator.dependencies(expression).each do |field|
        field_map.client_query(GrdaWarehouse::Hud::Client.none, field)
      rescue ArgumentError => e
        errors.add(:expression, :invalid, message: e.message)
      end
    end
  end
end
