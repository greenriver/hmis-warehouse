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
  let(:jwks_hash) { JSON.parse({ 'keys' => [jwk.export] }.to_json) }
  let(:payload) do
    {
      'email' => 'TEST@EXAMPLE.COM',
      'aud' => 'test_aud',
      'iss' => 'test_iss',
      'iat' => Time.now.to_i,
      'name' => '  John   Quincy   Adams  ',
      'federated_claims' => {
        'connector_id' => 'keycloak',
        'user_id' => 'kc-123',
      },
    }
  end
  let(:access_token) { JWT.encode(payload, rsa_key, 'RS256', { kid: kid }) }
  let(:helper) { described_class.new(access_token: access_token) }

  before do
    JwtHelper.memory_cache.clear
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('JWKS_URL').and_return(jwks_url)
    allow(ENV).to receive(:fetch).with('IDP_AUD').and_return('test_aud')
    allow(ENV).to receive(:fetch).with('ISS_URL').and_return('test_iss')
    allow(ENV).to receive(:fetch).with('JWT_ALGORITHM').and_return('RS256')

    allow(described_class).to receive(:fetch_jwks).and_return(jwks_hash)
  end

  describe '#token?' do
    it 'returns true when access_token is present' do
      expect(helper.token?).to be true
    end

    it 'returns false when access_token is nil' do
      nil_helper = described_class.new(access_token: nil)
      expect(nil_helper.token?).to be false
    end
  end

  describe '#validate!' do
    it 'returns true if token is valid' do
      expect(helper.validate!).to be true
    end

    it 'returns false if public key is missing' do
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

    it 'rejects a mismatched audience when IDP_AUD is blank (fail-closed)' do
      allow(ENV).to receive(:fetch).with('IDP_AUD').and_return('')
      bad_aud_payload = payload.merge('aud' => 'wrong_aud')
      bad_aud_token = JWT.encode(bad_aud_payload, rsa_key, 'RS256', { kid: kid })
      bad_aud_helper = described_class.new(access_token: bad_aud_token)
      expect(bad_aud_helper.validate!).to be false
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

    it 'returns nil if it does not match' do
      expect(helper.email('wrong@example.com')).to be_nil
    end
  end

  describe '#connector_user_id' do
    it 'reads user_id from federated_claims' do
      expect(helper.connector_user_id).to eq('kc-123')
    end

    it 'returns nil when federated_claims is absent' do
      no_claims_payload = payload.except('federated_claims')
      token = JWT.encode(no_claims_payload, rsa_key, 'RS256', { kid: kid })
      h = described_class.new(access_token: token)
      expect(h.connector_user_id).to be_nil
    end
  end

  describe '#connector_id' do
    it 'reads connector_id from federated_claims' do
      expect(helper.connector_id).to eq('keycloak')
    end

    it 'returns nil when federated_claims is absent' do
      no_claims_payload = payload.except('federated_claims')
      token = JWT.encode(no_claims_payload, rsa_key, 'RS256', { kid: kid })
      h = described_class.new(access_token: token)
      expect(h.connector_id).to be_nil
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

  describe '.assert_boot_config!' do
    before do
      allow(ENV).to receive(:fetch).with('IDP_AUD', '').and_return('test_aud')
      allow(ENV).to receive(:fetch).with('ISS_URL', '').and_return('test_iss')
      allow(ENV).to receive(:fetch).with('JWKS_URL', '').and_return(jwks_url)
      allow(ENV).to receive(:fetch).with('JWT_ALGORITHM', '').and_return('RS256')
    end

    it 'passes when all required env keys are present' do
      expect { described_class.assert_boot_config! }.not_to raise_error
    end

    it 'raises naming the missing key when one is absent' do
      allow(ENV).to receive(:fetch).with('IDP_AUD', '').and_return('')
      expect { described_class.assert_boot_config! }.to raise_error(RuntimeError, /IDP_AUD/)
    end
  end

  describe 'JWKS key rotation' do
    let(:new_rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
    let(:new_kid) { 'rotated_kid' }
    let(:new_jwk) { JWT::JWK.new(new_rsa_key, kid: new_kid) }
    let(:rotated_jwks_hash) { JSON.parse({ 'keys' => [jwk.export, new_jwk.export] }.to_json) }
    let(:rotated_token) { JWT.encode(payload, new_rsa_key, 'RS256', { kid: new_kid }) }

    it 're-fetches JWKS when a new kid appears after key rotation' do
      call_count = 0
      allow(described_class).to receive(:fetch_jwks) do
        call_count += 1
        if call_count == 1
          jwks_hash
        else
          rotated_jwks_hash
        end
      end

      # Warm the cache with the original keyset (missing the rotated kid)
      described_class.new(access_token: access_token).validate!

      # Now validate a token signed with the rotated key
      rotated_helper = described_class.new(access_token: rotated_token)
      expect(rotated_helper.validate!).to be true
      expect(call_count).to eq(2)
    end

    it 'returns false after one retry for a genuinely unknown kid' do
      unknown_key = OpenSSL::PKey::RSA.generate(2048)
      unknown_token = JWT.encode(payload, unknown_key, 'RS256', { kid: 'never_in_jwks' })
      unknown_helper = described_class.new(access_token: unknown_token)

      expect(described_class).to receive(:fetch_jwks).twice.and_return(jwks_hash)
      expect(unknown_helper.validate!).to be false
    end
  end
end
