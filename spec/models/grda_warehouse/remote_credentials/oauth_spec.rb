# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::RemoteCredentials::Oauth do
  describe 'attribute assignment' do
    it 'assigns client_secret correctly' do
      oauth = described_class.new(
        client_id: 'client123',
        client_secret: 'secret123',
        token_url: 'https://oauth.example.com/token',
        base_url: 'https://api.example.com',
        oauth_scope: 'read write',
      )
      expect(oauth.client_secret).to eq('secret123')
    end
  end
end
