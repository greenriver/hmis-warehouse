# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::RemoteCredentials::SymmetricEncryptionKey do
  describe 'attribute assignment' do
    it 'assigns key_hex correctly' do
      key = described_class.new(
        algorithm: 'AES-256-CBC',
        key_hex: '0123456789abcdef'
      )
      expect(key.key_hex).to eq('0123456789abcdef')
    end
  end
end
