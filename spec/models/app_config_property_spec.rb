# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppConfigProperty, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:key) }

    it 'validates uniqueness of key' do
      create(:app_config_property, key: 'duplicate')
      new_prop = build(:app_config_property, key: 'duplicate')
      expect(new_prop).not_to be_valid
    end

    describe 'json validation' do
      it 'is valid with valid JSON object via value_input' do
        prop = build(:app_config_property, value_input: '{"foo": "bar"}')
        expect(prop).to be_valid
        prop.save
        expect(prop.reload.value).to eq({ 'foo' => 'bar' })
      end

      it 'is valid with valid JSON array via value_input' do
        prop = build(:app_config_property, value_input: '[1, 2, 3]')
        expect(prop).to be_valid
        prop.save
        expect(prop.reload.value).to eq([1, 2, 3])
      end

      it 'is valid with a simple JSON string via value_input' do
        prop = build(:app_config_property, value_input: '"simple string"')
        expect(prop).to be_valid
        prop.save
        expect(prop.reload.value).to eq('simple string')
      end

      it 'is invalid with malformed JSON via value_input' do
        prop = build(:app_config_property, value_input: '{"foo": "bar"')
        expect(prop).not_to be_valid
        expect(prop.errors[:value_input]).to include(/is not valid JSON/)
      end

      it 'is invalid when value_input is blank' do
        prop = build(:app_config_property, value_input: '')
        expect(prop).not_to be_valid
        expect(prop.errors[:value_input]).to include("can't be blank")
      end

      it 'is valid when value is already a Hash' do
        prop = build(:app_config_property, value: { foo: 'bar' })
        expect(prop).to be_valid
      end
    end
  end

  describe 'strip_whitespace' do
    it 'strips whitespace from key' do
      prop = create(:app_config_property, key: '  spaced_key  ')
      expect(prop.key).to eq('spaced_key')
    end
  end
end
