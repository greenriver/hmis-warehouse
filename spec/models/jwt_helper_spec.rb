###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtHelper do
  let(:jwks_url) { 'http://example.com/jwks' }
  let(:kid) { 'test_kid' }
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:jwk) { JWT::JWK.new(rsa_key, kid: kid) }
  let(:jwks_hash) { { 'keys' => [jwk.export] } }
  let(:payload) do
    {
      'email' => 'TEST@EXAMPLE.COM',
      'aud' => 'test_aud',
      'iss' => 'test_iss',
      'iat' => Time.now.to_i,
      'name' => '  John   Quincy   Adams  ',
    }
  end
  let(:access_token) { JWT.encode(payload, rsa_key, 'RS256', { kid: kid }) }
  let(:helper) { described_class.new(access_token: access_token) }

  before do
    JwtHelper.memory_cache.clear
    allow(ENV).to receive(:fetch).with('JWKS_URL').and_return(jwks_url)
    allow(ENV).to receive(:fetch).with('IDP_AUD', any_args).and_return('test_aud')
    allow(ENV).to receive(:fetch).with('ISS_URL').and_return('test_iss')
    allow(ENV).to receive(:fetch).with('JWT_ALGORITHM').and_return('RS256')

    allow(Net::HTTP).to receive(:get).with(URI(jwks_url)).and_return(jwks_hash.to_json)
  end

  describe '#token?' do
    it 'returns true when access_token is present' do
      expect(helper.token?).to be true
    end

    it 'returns false when access_token is nil' do
      helper.access_token = nil
      expect(helper.token?).to be false
    end
  end

  describe '#validate!' do
    it 'returns true if token is valid' do
      expect(helper.validate!).to be true
    end

    it 'returns false if public key is missing' do
      # Create a token with a different kid
      bad_token = JWT.encode(payload, rsa_key, 'RS256', { kid: 'wrong_kid' })
      bad_helper = described_class.new(access_token: bad_token)
      expect(bad_helper.validate!).to be false
    end

    it 'returns false if token is expired' do
      expired_payload = payload.merge('exp' => Time.now.to_i - 3600)
      expired_token = JWT.encode(expired_payload, rsa_key, 'RS256', { kid: kid })
      expired_helper = described_class.new(access_token: expired_token)
      expect(expired_helper.validate!).to be false
    end

    it 'returns false if issuer is invalid' do
      bad_iss_payload = payload.merge('iss' => 'wrong_iss')
      bad_iss_token = JWT.encode(bad_iss_payload, rsa_key, 'RS256', { kid: kid })
      bad_iss_helper = described_class.new(access_token: bad_iss_token)
      expect(bad_iss_helper.validate!).to be false
    end

    it 'returns false if audience is invalid' do
      bad_aud_payload = payload.merge('aud' => 'wrong_aud')
      bad_aud_token = JWT.encode(bad_aud_payload, rsa_key, 'RS256', { kid: kid })
      bad_aud_helper = described_class.new(access_token: bad_aud_token)
      expect(bad_aud_helper.validate!).to be false
    end

    it 'skips audience validation if IDP_AUD is blank' do
      allow(ENV).to receive(:fetch).with('IDP_AUD', any_args).and_return('')
      bad_aud_payload = payload.merge('aud' => 'wrong_aud')
      bad_aud_token = JWT.encode(bad_aud_payload, rsa_key, 'RS256', { kid: kid })
      bad_aud_helper = described_class.new(access_token: bad_aud_token)
      expect(bad_aud_helper.validate!).to be true
    end
  end

  describe '#payload' do
    it 'returns the decoded payload and header' do
      result_payload, result_header = helper.payload
      expect(result_payload['email']).to eq('TEST@EXAMPLE.COM')
      expect(result_header['kid']).to eq(kid)
    end
  end

  describe '#payload_email' do
    it 'returns downcased email from payload' do
      expect(helper.payload_email).to eq('test@example.com')
    end
  end

  describe '#email' do
    it 'returns the email if it matches the forwarded email (case insensitive)' do
      expect(helper.email('test@example.com')).to eq('test@example.com')
      expect(helper.email('TEST@EXAMPLE.COM')).to eq('test@example.com')
    end

    it 'returns false if it does not match' do
      expect(helper.email('wrong@example.com')).to be false
    end
  end

  describe 'name parsing' do
    it '#first_name returns the titleized first part' do
      expect(helper.first_name).to eq('John')
    end

    it '#last_name returns the titleized last part' do
      expect(helper.last_name).to eq('Adams')
    end

    it '#last_name returns empty string if only one name exists' do
      single_name_payload = payload.merge('name' => 'Cher')
      single_name_token = JWT.encode(single_name_payload, rsa_key, 'RS256', { kid: kid })
      single_name_helper = described_class.new(access_token: single_name_token)
      expect(single_name_helper.last_name).to eq('')
    end
  end

  describe '#jwks (private)' do
    it 'fetches and parses JWKS at the instance level' do
      expect(helper.send(:jwks)).to eq(JSON.parse(jwks_hash.to_json))
    end

    it 'memoizes the result at the instance level' do
      expect(Net::HTTP).to receive(:get).once.and_return(jwks_hash.to_json)
      helper.send(:jwks)
      helper.send(:jwks)
    end
  end

  describe '#public_key (private)' do
    it 'returns an OpenSSL::PKey::RSA object' do
      public_key = helper.send(:public_key)
      expect(public_key).to be_a(OpenSSL::PKey::RSA)
      expect(public_key.to_pem).to eq(rsa_key.public_key.to_pem)
    end

    it 'returns nil if the kid is not found in JWKS' do
      allow(helper).to receive(:header).and_return({ 'kid' => 'unknown' })
      expect(helper.send(:public_key)).to be_nil
    end
  end
end
