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

      aggregate_failures do
        combinations.each do |(type, response, indefinite_and_impairs)|
          row = described_class::DisabilityRow.new(
            client_id: nil,
            type: type,
            response: response,
            indefinite_and_impairs: indefinite_and_impairs,
            information_date: nil,
          )
          warehouse_disability = GrdaWarehouse::Hud::Disability.new(
            DisabilityType: type,
            DisabilityResponse: response,
            IndefiniteAndImpairs: indefinite_and_impairs,
          )

          ce_qualifies = inference.send(:qualifies?, row)
          warehouse_qualifies = warehouse_disability.indefinite_and_impairs?

          expect(ce_qualifies).to eq(warehouse_qualifies),
                                  "type #{type}, response #{response.inspect}, " \
                                  "IndefiniteAndImpairs #{indefinite_and_impairs.inspect}"
        end
      end
    end
  end
end
