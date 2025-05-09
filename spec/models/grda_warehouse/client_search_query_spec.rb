# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientSearchQuery, type: :model do
  let(:user) { create(:user) }
  let(:valid_params) do
    {
      'q' => 'test search',
      'client' => {
        'first_name' => 'John',
        'last_name' => 'Doe',
        'dob' => '1990-01-01',
        'ssn' => '123456789',
      },
    }
  end

  describe '.permit_params' do
    let(:params) { ActionController::Parameters.new(valid_params) }

    it 'permits valid parameters' do
      result = described_class.permit_params(params)
      expect(result).to be_present
      expect(result['q']).to eq('test search')
      expect(result['client']['first_name']).to eq('John')
    end

    it 'rejects invalid top-level parameters' do
      params = ActionController::Parameters.new(valid_params.merge('invalid' => 'value'))
      result = described_class.permit_params(params)
      expect(result).to be_present
      expect(result['invalid']).to be_nil
    end

    it 'rejects invalid client parameters' do
      params = ActionController::Parameters.new(valid_params.deep_merge('client' => { 'invalid' => 'value' }))
      result = described_class.permit_params(params)
      expect(result).to be_present
      expect(result['client']['invalid']).to be_nil
    end

    it 'returns nil for empty params' do
      params = ActionController::Parameters.new({})
      expect(described_class.permit_params(params)).to be_nil
    end
  end

  describe 'validations' do
    it 'is valid with valid params' do
      query = described_class.new(params: valid_params, created_by: user)
      expect(query).to be_valid
    end

    it 'is invalid with invalid top-level parameters' do
      params = valid_params.merge('invalid_param' => 'value')
      query = described_class.new(params: params)
      expect(query).not_to be_valid
      expect(query.errors[:params]).to include(/contains invalid parameters/)
    end

    it 'is invalid with invalid client parameters' do
      params = valid_params.deep_merge('client' => { 'invalid_field' => 'value' })
      query = described_class.new(params: params)
      expect(query).not_to be_valid
      expect(query.errors[:params]).to include(/contains invalid client parameters/)
    end

    it 'is invalid with string exceeding max length' do
      params = valid_params.deep_merge('q' => 'a' * 101)
      query = described_class.new(params: params)
      expect(query).not_to be_valid
      expect(query.errors[:params]).to include(/is too long/)
    end

    it 'is invalid with client string exceeding max length' do
      params = valid_params.deep_merge('client' => { 'first_name' => 'a' * 101 })
      query = described_class.new(params: params)
      expect(query).not_to be_valid
      expect(query.errors[:params]).to include(/first_name is too long/)
    end
  end

  describe '.normalize_params' do
    it 'handles nil params' do
      expect(described_class.normalize_params(nil)).to eq({})
    end

    it 'strips whitespace from strings' do
      params = { 'q' => '  test  ' }
      expect(described_class.normalize_params(params)).to eq({ 'q' => 'test' })
    end

    it 'removes blank values' do
      params = { 'q' => 'test', 'empty' => '' }
      expect(described_class.normalize_params(params)).to eq({ 'q' => 'test' })
    end

    it 'sorts parameters' do
      params = { 'b' => '2', 'a' => '1' }
      expect(described_class.normalize_params(params).keys).to eq(['a', 'b'])
    end

    it 'handles nested hashes' do
      params = {
        'client' => {
          'first_name' => '  John  ',
          'last_name' => '  Doe  ',
        },
      }
      expected = {
        'client' => {
          'first_name' => 'John',
          'last_name' => 'Doe',
        },
      }
      expect(described_class.normalize_params(params)).to eq(expected)
    end
  end

  describe '.find_or_create_by_params!' do
    it 'creates a new query with valid params' do
      expect do
        described_class.find_or_create_by_params!(valid_params, user: user)
      end.to change(described_class, :count).by(1)
    end

    it 'reuses existing query with same params' do
      described_class.find_or_create_by_params!(valid_params, user: user)
      expect do
        described_class.find_or_create_by_params!(valid_params, user: user)
      end.not_to change(described_class, :count)
    end

    it 'creates new query with different params' do
      described_class.find_or_create_by_params!(valid_params, user: user)
      new_params = valid_params.deep_merge('q' => 'different search')
      expect do
        described_class.find_or_create_by_params!(new_params, user: user)
      end.to change(described_class, :count).by(1)
    end
  end
end
