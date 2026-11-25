# frozen_string_literal: true

require 'rails_helper'

# Resolution behavior is covered through the PSDE fields in psde_value_resolver_spec.rb and
# psde_disabling_condition_parity_spec.rb.
RSpec.describe Hmis::Ce::Match::Expression::DisablingConditionInference, type: :model do
  let(:eligibility_scope) { Hmis::Ce::Match::Expression::EnrollmentEligibilityScope.new }
  let(:inference) { described_class.new(eligibility_scope: eligibility_scope, definition: :hud) }

  it 'rejects an unknown definition' do
    expect { described_class.new(eligibility_scope: eligibility_scope, definition: :other) }.to raise_error(ArgumentError)
  end

  describe 'HUD disabling condition row test' do
    it 'agrees with GrdaWarehouse::Hud::Disability#indefinite_and_impairs? for every combination' do
      types = 5..10
      responses = [0, 1, 2, 3, 8, 9, 99, nil]
      indefinite_and_impairs_values = [0, 1, 8, 9, 99, nil]
      combinations = types.to_a.product(responses, indefinite_and_impairs_values)

      # Evaluate the SQL row test against every combination at once, using a VALUES list that stands in for the
      # Disabilities table.
      connection = Hmis::Hud::Disability.connection
      values_sql = combinations.each_with_index.map do |values, index|
        "(#{[index, *values].map { |value| connection.quote(value) }.join(', ')})"
      end.join(', ')
      qualifies_sql = inference.send(:qualifies_condition).to_sql
      ce_qualifies_by_index = connection.select_rows(<<~SQL).to_h
        SELECT combination_index, (#{qualifies_sql}) IS TRUE
        FROM (VALUES #{values_sql})
          AS "Disabilities"(combination_index, "DisabilityType", "DisabilityResponse", "IndefiniteAndImpairs")
      SQL

      aggregate_failures do
        combinations.each_with_index do |(type, response, indefinite_and_impairs), index|
          warehouse_disability = GrdaWarehouse::Hud::Disability.new(
            DisabilityType: type,
            DisabilityResponse: response,
            IndefiniteAndImpairs: indefinite_and_impairs,
          )

          ce_qualifies = ce_qualifies_by_index.fetch(index)
          warehouse_qualifies = warehouse_disability.indefinite_and_impairs?

          expect(ce_qualifies).to eq(warehouse_qualifies),
                                  "type #{type}, response #{response.inspect}, " \
                                  "IndefiniteAndImpairs #{indefinite_and_impairs.inspect}"
        end
      end
    end
  end
end
