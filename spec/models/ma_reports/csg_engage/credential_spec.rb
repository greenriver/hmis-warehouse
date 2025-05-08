# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaReports::CsgEngage::Credential do
  describe 'attribute assignment' do
    it 'assigns apikey correctly' do
      credential = described_class.new(
        endpoint: 'https://api.example.com',
        apikey: 'key123'
      )
      expect(credential.apikey).to eq('key123')
    end
  end
end
