# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::Oauth2ProxySignInPath do
  describe '.call' do
    it 'returns the bare path when no connector_id or redirect is given' do
      expect(described_class.call).to eq('/oauth2/sign_in')
    end

    it 'appends the connector_id when present' do
      expect(described_class.call(connector_id: 'keycloak')).to eq('/oauth2/sign_in?connector_id=keycloak')
    end

    it 'escapes the connector_id' do
      expect(described_class.call(connector_id: 'foo bar')).to eq('/oauth2/sign_in?connector_id=foo+bar')
    end

    it 'appends and escapes the redirect_to as the rd parameter' do
      expect(described_class.call(redirect_to: '/admin/users?page=2')).
        to eq('/oauth2/sign_in?rd=%2Fadmin%2Fusers%3Fpage%3D2')
    end

    it 'includes both connector_id and rd when present' do
      expect(described_class.call(connector_id: 'keycloak', redirect_to: '/dashboard')).
        to eq('/oauth2/sign_in?connector_id=keycloak&rd=%2Fdashboard')
    end

    it 'ignores blank values' do
      expect(described_class.call(connector_id: '', redirect_to: '')).to eq('/oauth2/sign_in')
    end
  end
end
