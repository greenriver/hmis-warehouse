# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::CalculatorFactory do
  describe '.build' do
    it 'creates a calculator with custom functions' do
      calculator = described_class.build
      expect(calculator).to be_a(Dentaku::Calculator)
    end

    context 'with DAYS_AGO function' do
      let(:current_date) { Date.new(2024, 12, 26) }
      let(:calculator) { described_class.build(current_date: current_date) }

      it 'calculates days between current date and provided date' do
        past_date = Date.new(2024, 12, 20)
        result = calculator.evaluate('DAYS_AGO(date)', date: past_date)
        expect(result).to eq(6)
      end

      it 'handles negative values for future dates' do
        future_date = Date.new(2024, 12, 30)
        result = calculator.evaluate('DAYS_AGO(date)', date: future_date)
        expect(result).to eq(-4)
      end

      it 'handles string dates' do
        result = calculator.evaluate('DAYS_AGO(date)', date: '2024-12-20')
        expect(result).to eq(6)
      end

      it 'handles nil values' do
        result = calculator.evaluate('DAYS_AGO(date)', date: nil)
        expect(result).to be_nil
      end

      it 'raises error for invalid date strings' do
        expect {
          calculator.evaluate('DAYS_AGO(date)', date: 'invalid-date')
        }.to raise_error(Date::Error)
      end

      it 'handles non-date values' do
        result = calculator.evaluate('DAYS_AGO(date)', date: 123)
        expect(result).to be_nil
      end

      it 'can be used in expressions' do
        result = calculator.evaluate('DAYS_AGO(date) > 5', date: Date.new(2024, 12, 20))
        expect(result).to be(true)
      end

      it 'uses the provided current_date consistently' do
        different_current_date = Date.new(2024, 1, 1)
        different_calculator = described_class.build(current_date: different_current_date)

        test_date = Date.new(2023, 12, 25)
        result = different_calculator.evaluate('DAYS_AGO(date)', date: test_date)
        expect(result).to eq(7) # 2024-01-01 - 2023-12-25 = 7 days
      end

      it 'works with complex boolean expressions' do
        # Test that DAYS_AGO function can be used in realistic expressions
        result = calculator.evaluate('current_age > 18 AND DAYS_AGO(some_date) > 5',
                                     current_age: 25,
                                     some_date: Date.new(2024, 12, 20))
        expect(result).to be(true) # 25 > 18 AND 6 > 5 = true

        # Test with a date that doesn't meet the criteria
        result = calculator.evaluate('current_age > 18 AND DAYS_AGO(some_date) > 10',
                                     current_age: 25,
                                     some_date: Date.new(2024, 12, 20))
        expect(result).to be(false) # 25 > 18 AND 6 > 10 = false
      end
    end

    context 'with existing functions' do
      let(:calculator) { described_class.build }

      it 'supports INCLUDES function' do
        result = calculator.evaluate('INCLUDES(array, value)', array: [1, 2, 3], value: 2)
        expect(result).to be(true)
      end

      it 'supports EXCLUDES function' do
        result = calculator.evaluate('EXCLUDES(array, value)', array: [1, 2, 3], value: 4)
        expect(result).to be(true)
      end
    end
  end
end
