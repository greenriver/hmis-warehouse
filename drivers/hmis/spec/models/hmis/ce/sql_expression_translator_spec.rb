# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::SqlExpressionTranslator do
  let(:field_map) { Hmis::Ce::Match::Expression::FieldMap.new }

  describe '.call' do
    it 'handles simple comparisons' do
      result = described_class.call('current_age > 18', field_map)
      expect(result.to_sql).to include('DATE_PART')
      expect(result.to_sql).to include('> 18')
    end

    it 'handles AND conditions' do
      result = described_class.call('current_age > 18 AND veteran_status = 1', field_map)
      expect(result.to_sql).to include('AND')
      expect(result.to_sql).to include('"Client"."VeteranStatus"')
    end

    it 'handles nested conditions' do
      result = described_class.call(
        '(current_age > 18 AND veteran_status = 1) OR current_age >= 65',
        field_map,
      )
      sql = result.to_sql
      expect(sql).to include('OR')
      expect(sql).to include('AND')
      expect(sql.scan('DATE_PART').count).to eq(2) # Should appear twice for the two age comparisons
    end

    it 'handles unsupported fields gracefully' do
      result = described_class.call(
        'current_age > 18 AND unsupported_field = 1',
        field_map,
      )
      expect(result.to_sql).to include('DATE_PART')
      expect(result.to_sql).to include('> 18')
      expect(result.to_sql).to include('1 = 1') # ALWAYS_TRUE for unsupported field
    end

    it 'handles simple addition' do
      result = described_class.call('current_age = (5 + 5)', field_map)
      expect(result.to_sql).to include('= (5 + 5)')
    end

    it 'handles complex arithmetic' do
      result = described_class.call('current_age = (10 * 2 + 5)', field_map)
      expect(result.to_sql).to include('= ((10 * 2) + 5)')
    end

    it 'handles division' do
      result = described_class.call('current_age = (100 / 2)', field_map)
      expect(result.to_sql).to include('= (100 / 2)')
    end

    it 'handles modulo' do
      result = described_class.call('current_age = (7 % 2)', field_map)
      expect(result.to_sql).to include('% 2')
    end

    it 'handles exponentiation' do
      result = described_class.call('current_age = (2 ^ 3)', field_map)
      expect(result.to_sql).to include('POWER')
    end

    it 'handles mixing math with field references' do
      result = described_class.call('current_age = (veteran_status + 5)', field_map)
      expect(result.to_sql).to include('"Client"."VeteranStatus"')
      expect(result.to_sql).to include('+ 5')
    end

    it 'handles nested arithmetic expressions' do
      result = described_class.call('current_age = ((10 + 5) * (2 + 3))', field_map)
      expect(result.to_sql).to include('((10 + 5) * (2 + 3))')
    end

    context 'with fields that cannot be resolved into SQL' do
      it 'handles a simple comparison with an unresolvable field' do
        result = described_class.call('unresolvable_field = 1', field_map)
        expect(result.to_sql).to eq('(1 = 1)')
      end

      it 'handles AND with an unresolvable field by preserving the known condition' do
        result = described_class.call('unresolvable_field = 1 AND current_age > 18', field_map)
        sql = result.to_sql
        expect(sql).to include('DATE_PART')
        expect(sql).to include('> 18')
        expect(sql).not_to include('1 = 1 = 1') # Should not have invalid SQL
      end

      it 'handles OR with an unresolvable field by making the expression always true' do
        result = described_class.call('unresolvable_field = 1 OR current_age > 18', field_map)
        sql = result.to_sql
        expect(sql).to include('(1 = 1) OR')
        expect(sql).to include('DATE_PART')
        expect(sql).to include('> 18')
      end

      it 'handles INCLUDES with unresolvable field by making the expression always true' do
        result = described_class.call('INCLUDES(open_enrollment_project_types, 14)', field_map)
        expect(result.to_sql).to eq('1 = 1')
      end

      it 'handles multiple unresolvable fields in an AND expression' do
        result = described_class.call('unresolvable_field1 = 1 AND unresolvable_field2 = 2', field_map)
        sql = result.to_sql
        expect(sql).to include('(1 = 1) AND (1 = 1)')
      end

      it 'handles a complex expression with mixed resolvable and unresolvable fields' do
        result = described_class.call(
          '(unresolvable_field = 1 AND current_age > 18) OR veteran_status = 1',
          field_map,
        )
        sql = result.to_sql
        expect(sql).to include('"Client"."VeteranStatus"')
        expect(sql).to include('= 1')
        # Should contain the veteran_status condition since it's in an OR with a condition that includes unresolvable field
      end
    end
  end
end
