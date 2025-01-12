require 'rails_helper'

RSpec.describe Hmis::Form::NumericInputValidator do
  let(:validator) { described_class.new }

  def config_to_item(config)
    Oj.load(config.to_json, mode: :compat, object_class: OpenStruct)
  end

  shared_examples 'validates special values' do
    it 'accepts blank values' do
      expect(validator.call(item, '')).to be_empty
      expect(validator.call(item, nil)).to be_empty
    end

    it 'accepts special system values' do
      expect(validator.call(item, 'DATA_NOT_COLLECTED')).to be_empty
      expect(validator.call(item, '_HIDDEN')).to be_empty
    end
  end

  describe 'currency validation' do
    let(:item) { config_to_item({ type: 'CURRENCY', bounds: [] }) }

    include_examples 'validates special values'

    it 'accepts valid currency formats' do
      valid_currencies = ['0', '0.0', '0.00', '1', '1.0', '1.00', '-1', '-1.0', '-1.00', '1234.56']
      valid_currencies.each do |value|
        expect(validator.call(item, value)).to be_empty, "Expected #{value} to be valid"
      end
    end

    it 'rejects invalid currency formats' do
      invalid_currencies = ['abc', '1.234', '01', '00', '1a', 'a1', '.1', '1.', '001']
      invalid_currencies.each do |value|
        expect(validator.call(item, value)).to eq(['not a valid currency amount']), "Expected #{value} to be invalid"
      end
    end

    context 'with bounds' do
      let(:item) do
        config_to_item(
          {
            type: 'CURRENCY',
            bounds: [
              { type: 'MIN', value_number: 0, severity: 'error' },
              { type: 'MAX', value_number: 100, severity: 'error' },
            ],
          },
        )
      end

      it 'validates within bounds' do
        expect(validator.call(item, '50')).to be_empty
      end

      it 'rejects values outside bounds' do
        expect(validator.call(item, '-1')).to include('must be greater than or equal to 0')
        expect(validator.call(item, '101')).to include('must be less than or equal to 100')
      end
    end

    context 'with null bounds' do
      let(:item) do
        config_to_item(
          {
            type: 'CURRENCY',
            bounds: [
              { type: 'MAX', value_number: nil, severity: 'error' },
            ],
          },
        )
      end

      it 'passes validation' do
        expect(validator.call(item, '50')).to be_empty
      end
    end
  end

  describe 'integer validation' do
    let(:item) { config_to_item({ type: 'INTEGER', bounds: [] }) }

    include_examples 'validates special values'

    it 'accepts valid integer formats' do
      valid_integers = ['0', '1', '-1', '1234', '-1234']
      valid_integers.each do |value|
        expect(validator.call(item, value)).to be_empty, "Expected #{value} to be valid"
      end
    end

    it 'rejects invalid integer formats' do
      invalid_integers = ['1.0', 'abc', '01', '00', '1a', 'a1', '.1', '1.', '001']
      invalid_integers.each do |value|
        expect(validator.call(item, value)).to eq(['not a valid integer']), "Expected #{value} to be invalid"
      end
    end
  end
end
