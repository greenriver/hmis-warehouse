# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::NullSafeOrderComparators do
  let(:calculator) { Hmis::Ce::Match::Expression::CalculatorFactory.build }

  describe 'order comparators with NULL operands' do
    it 'returns false for > when the left operand is NULL' do
      expect(calculator.evaluate!('score > 8', score: nil)).to be(false)
    end

    it 'returns false for >= when the left operand is NULL' do
      expect(calculator.evaluate!('score >= 8', score: nil)).to be(false)
    end

    it 'returns false for < when the left operand is NULL' do
      expect(calculator.evaluate!('fpl < 200', fpl: nil)).to be(false)
    end

    it 'returns false for <= when the left operand is NULL' do
      expect(calculator.evaluate!('fpl <= 200', fpl: nil)).to be(false)
    end

    it 'returns false when NULL is on the right' do
      expect(calculator.evaluate!('200 < fpl', fpl: nil)).to be(false)
    end

    it 'returns false when both operands are NULL' do
      expect(calculator.evaluate!('score > other_score', score: nil, other_score: nil)).to be(false)
    end

    it 'returns false for NULL literal comparisons' do
      expect(calculator.evaluate!('NULL > 5', {})).to be(false)
    end
  end

  describe 'compound expressions' do
    it 'keeps explicit NULL guards unchanged when score is NULL' do
      expect(calculator.evaluate!('score != NULL AND score >= 8', score: nil)).to be(false)
    end

    it 'keeps explicit NULL guards unchanged when score is present' do
      expect(calculator.evaluate!('score != NULL AND score >= 8', score: 10)).to be(true)
    end

    it 'returns false for AND when a comparator operand is NULL' do
      expect(calculator.evaluate!('score >= 8 AND status = 1', score: nil, status: 1)).to be(false)
    end

    it 'short-circuits OR when the comparator operand is NULL' do
      expect(calculator.evaluate!('score >= 8 OR veteran = TRUE', score: nil, veteran: true)).to be(true)
    end

    it 'returns false for OR when both sides are false' do
      expect(calculator.evaluate!('score >= 8 OR veteran = TRUE', score: nil, veteran: false)).to be(false)
    end

    it 'returns false for IF when the comparator operand is NULL' do
      expect(calculator.evaluate!('IF(score >= 8, TRUE, FALSE)', score: nil)).to be(false)
    end
  end

  describe 'equality comparators (unchanged)' do
    it 'returns false for = when score is NULL' do
      expect(calculator.evaluate!('score = 8', score: nil)).to be(false)
    end

    it 'returns true for != when score is NULL' do
      expect(calculator.evaluate!('score != 8', score: nil)).to be(true)
    end
  end
end
