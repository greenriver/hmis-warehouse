###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::ExpressionTranslator do
  describe '.to_structured' do
    it 'returns nil for blank expression' do
      expect(described_class.to_structured(nil)).to be_nil
      expect(described_class.to_structured('   ')).to be_nil
    end

    it 'returns nil for parse errors' do
      expect(described_class.to_structured('this is not an expression')).to be_nil
    end

    it 'parses a single comparison as implicit AND' do
      structured = described_class.to_structured('current_age >= 18')
      expect(structured.operator).to eq(:AND)
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to eq(
        Hmis::Ce::Match::Expression::StructuredExpression::Clause.new(field: 'current_age', comparator: :GTE, value: 18),
      )
    end

    it 'parses flat AND' do
      expr = 'current_age >= 18 AND veteran = TRUE AND score = 10'
      structured = described_class.to_structured(expr)
      expect(structured.operator).to eq(:AND)
      expect(structured.clauses.map(&:comparator)).to eq([:GTE, :EQ, :EQ])
      expect(structured.clauses.map(&:field)).to eq(['current_age', 'veteran', 'score'])
    end

    it 'parses flat OR' do
      expr = 'a = 1 OR b = 2 OR c = 3'
      structured = described_class.to_structured(expr)
      expect(structured.operator).to eq(:OR)
      expect(structured.clauses.size).to eq(3)
    end

    it 'parses INCLUDES with backtick field identifier' do
      expr = 'INCLUDES(`cde.custom_assessment.housing_needs_preferred_bedroom_size`, "1 Bed")'
      structured = described_class.to_structured(expr)
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to have_attributes(
        field: 'cde.custom_assessment.housing_needs_preferred_bedroom_size',
        comparator: :INCLUDES,
        value: '1 Bed',
      )
    end

    it 'parses EXCLUDES' do
      structured = described_class.to_structured('EXCLUDES(foo, 1)')
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to have_attributes(field: 'foo', comparator: :EXCLUDES, value: 1)
    end

    it 'parses EQ with NULL RHS' do
      structured = described_class.to_structured('foo = NULL')
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to have_attributes(field: 'foo', comparator: :EQ, value: nil)
    end

    it 'returns nil for INCLUDES with arguments in wrong order' do
      expect(described_class.to_structured('INCLUDES("1 Bed", foo)')).to be_nil
    end

    it 'returns nil when AND and OR are mixed at the same level' do
      expect(described_class.to_structured('a = 1 OR b = 2 AND c = 3')).to be_nil
    end

    it 'returns nil for nested boolean under a flat combinator' do
      expect(described_class.to_structured('a = 1 OR (b = 2 AND c = 3)')).to be_nil
    end

    it 'returns nil for disallowed functions' do
      expect(described_class.to_structured('PROJECT_TYPE(x) = "ES"')).to be_nil
    end

    it 'returns nil when comparing two identifiers' do
      expect(described_class.to_structured('a = b')).to be_nil
    end

    it 'returns nil for arithmetic' do
      expect(described_class.to_structured('a + 1 = 2')).to be_nil
    end
  end

  describe 'round-trip' do
    it 'preserves structured form for AND expressions' do
      original = 'current_age >= 18 AND veteran = TRUE'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form for OR expressions' do
      original = 'x = 1 OR y = 2'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form for INCLUDES in an AND chain' do
      original = 'INCLUDES(`cde.custom_assessment.k`, "v") AND a = 1'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form for EXCLUDES in an OR chain' do
      original = 'EXCLUDES(foo, 2) OR a = NULL'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form when clause value is NULL' do
      original = 'x = NULL'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end
  end
end
