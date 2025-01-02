require 'rails_helper'

RSpec.describe SqlHelper do
  describe '.quote_sql_array' do
    context 'with type parameter' do
      it 'quotes string arrays correctly' do
        result = described_class.quote_sql_array(['foo', 'bar'], type: 'text')
        expect(result).to eq("'{\"foo\",\"bar\"}'::text[]")
      end

      it 'quotes integer arrays correctly' do
        result = described_class.quote_sql_array([1, 2, 3], type: 'integer')
        expect(result).to eq("'{1,2,3}'::integer[]")
      end

      it 'quotes symbol arrays correctly' do
        result = described_class.quote_sql_array([:foo, :bar], type: 'text')
        expect(result).to eq("'{\"foo\",\"bar\"}'::text[]")
      end

      it 'handles mixed arrays of strings and integers' do
        result = described_class.quote_sql_array(['foo', 1, 'bar'], type: 'text')
        expect(result).to eq("'{\"foo\",1,\"bar\"}'::text[]")
      end

      it 'handles empty arrays' do
        result = described_class.quote_sql_array([], type: 'text')
        expect(result).to eq("'{}'::text[]")
      end

      it 'escapes special characters in strings' do
        result = described_class.quote_sql_array(['foo"bar', 'baz\'qux'], type: 'text')
        expect(result).to eq("'{\"foo\"bar\",\"baz''qux\"}'::text[]")
      end
    end

    context 'without type parameter' do
      it 'returns quoted array without type casting' do
        result = described_class.quote_sql_array(['foo', 'bar'], type: nil)
        expect(result).to eq("'{\"foo\",\"bar\"}'")
      end
    end

    context 'with invalid input' do
      it 'raises ArgumentError for unsupported types' do
        expect do
          described_class.quote_sql_array([Object.new], type: 'text')
        end.to raise_error(ArgumentError, /Invalid element type/)
      end
      it 'raises ArgumentError for nil types' do
        expect do
          described_class.quote_sql_array([nil, 'foo', nil], type: 'text')
        end.to raise_error(ArgumentError, /Invalid element type/)
      end
    end
  end

  describe '.non_empty_array_subset_condition' do
    it 'generates correct SQL condition for string arrays' do
      result = described_class.non_empty_array_subset_condition(
        field: 'tags',
        set: ['ruby', 'rails'],
        type: 'text',
      )
      expected = "tags <@ '{\"ruby\",\"rails\"}'::text[] AND tags != '{}'::text[]"
      expect(result).to eq(expected)
    end

    it 'generates correct SQL condition for integer arrays' do
      result = described_class.non_empty_array_subset_condition(
        field: 'numbers',
        set: [1, 2, 3],
        type: 'integer',
      )
      expected = "numbers <@ '{1,2,3}'::integer[] AND numbers != '{}'::integer[]"
      expect(result).to eq(expected)
    end

    it 'handles empty set correctly' do
      result = described_class.non_empty_array_subset_condition(
        field: 'tags',
        set: [],
        type: 'text',
      )
      expected = "tags <@ '{}'::text[] AND tags != '{}'::text[]"
      expect(result).to eq(expected)
    end
  end
end
