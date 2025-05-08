# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuiltForZeroReport::Credential do
  describe 'attribute assignment' do
    it 'assigns aliased attributes correctly' do
      credential = described_class.new(
        endpoint: 'https://api.example.com',
        apikey: 'key123',
        community_id: 'comm123'
      )
      expect(credential.apikey).to eq('key123')
      expect(credential.community_id).to eq('comm123')
    end
  end
end
