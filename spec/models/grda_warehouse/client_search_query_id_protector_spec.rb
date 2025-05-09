# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientSearchQueryIdProtector do
  let(:protector) { GrdaWarehouse::ClientSearchQueryIdProtector.instance }
  let(:valid_input) { 'abcdef123456' }

  describe '#encrypt' do
    it 'returns a URL-safe base64 encoded string' do
      result = protector.encrypt(valid_input)
      expect(result).to be_a(String)
      expect { Base64.urlsafe_decode64(result) }.not_to raise_error
    end

    it 'produces different outputs for the same input' do
      result1 = protector.encrypt(valid_input)
      result2 = protector.encrypt(valid_input)
      expect(result1).not_to eq(result2)
    end

    it 'ensures the encrypted result is different from the original input' do
      result = protector.encrypt(valid_input)
      expect(result).not_to eq(valid_input)
    end

    it 'has an output length within expected bounds' do
      result = protector.encrypt(valid_input)
      expect(result.length).to be > 100
      expect(result.length).to be < 300
    end

    it 'raises an error for invalid input' do
      expect { protector.encrypt('invalid input with spaces') }.to raise_error(/Input must contain only alphanumeric characters/)
      expect { protector.encrypt('invalid-with-dash') }.to raise_error(/Input must contain only alphanumeric characters/)
    end
  end

  describe '#decrypt' do
    it 'can decrypt what it encrypts' do
      encrypted = protector.encrypt(valid_input)
      decrypted = protector.decrypt(encrypted)
      expect(decrypted).to eq(valid_input)
    end

    it 'returns nil for invalid id' do
      expect(protector.decrypt('invalid-encrypted-text')).to be_nil
    end
  end
end
