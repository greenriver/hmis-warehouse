###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::JwtHelper, if: AuthMethod.jwt? do
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
    Idp::JwtHelper.memory_cache.clear
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

  describe '#valid?' do
    it 'returns true if token is valid' do
      expect(helper.valid?).to be true
    end

    it 'returns false if public key is missing' do
      bad_token = JWT.encode(payload, rsa_key, 'RS256', { kid: 'wrong_kid' })
      bad_helper = described_class.new(access_token: bad_token)
      expect(bad_helper.valid?).to be false
    end

    it 'returns false if token is expired' do
      expired_payload = payload.merge('exp' => Time.now.to_i - 3600)
      expired_token = JWT.encode(expired_payload, rsa_key, 'RS256', { kid: kid })
      expired_helper = described_class.new(access_token: expired_token)
      expect(expired_helper.valid?).to be false
    end

    it 'returns false if issuer is invalid' do
      bad_iss_payload = payload.merge('iss' => 'wrong_iss')
      bad_iss_token = JWT.encode(bad_iss_payload, rsa_key, 'RS256', { kid: kid })
      bad_iss_helper = described_class.new(access_token: bad_iss_token)
      expect(bad_iss_helper.valid?).to be false
    end

    it 'returns false if audience is invalid' do
      bad_aud_payload = payload.merge('aud' => 'wrong_aud')
      bad_aud_token = JWT.encode(bad_aud_payload, rsa_key, 'RS256', { kid: kid })
      bad_aud_helper = described_class.new(access_token: bad_aud_token)
      expect(bad_aud_helper.valid?).to be false
    end

    it 'rejects a mismatched audience when IDP_AUD is blank (fail-closed)' do
      allow(ENV).to receive(:fetch).with('IDP_AUD').and_return('')
      bad_aud_payload = payload.merge('aud' => 'wrong_aud')
      bad_aud_token = JWT.encode(bad_aud_payload, rsa_key, 'RS256', { kid: kid })
      bad_aud_helper = described_class.new(access_token: bad_aud_token)
      expect(bad_aud_helper.valid?).to be false
    end

    it 'fails closed (and reports to Sentry) when the JWKS endpoint is unreachable' do
      allow(described_class).to receive(:fetch_jwks).and_raise(SocketError.new('getaddrinfo: Name or service not known'))
      expect(Sentry).to receive(:capture_exception_with_info).with(instance_of(SocketError), anything)

      expect(helper.valid?).to be false
    end
  end

  # Lets a caller tell "nobody is signed in" apart from "our stack is misconfigured". #valid?
  # collapses both into false, which is why every caller guessed wrong.
  describe '#invalid_reason' do
    it 'is nil for a token that verifies' do
      expect(helper.invalid_reason).to be_nil
    end

    it 'is :missing when there is no token' do
      expect(described_class.new(access_token: nil).invalid_reason).to eq(:missing)
    end

    it 'is :malformed for something that is not a JWT at all' do
      expect(described_class.new(access_token: 'not-a-jwt').invalid_reason).to eq(:malformed)
    end

    # Not :malformed: this parses fine and names a key we hold. A token from somewhere else, not a
    # truncated one.
    it 'is :bad_signature when the token was signed by another key under a kid we hold' do
      other_key = OpenSSL::PKey::RSA.generate(2048)
      token = JWT.encode(payload, other_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).invalid_reason).to eq(:bad_signature)
    end

    it 'is :unknown_key when the kid is not in the JWKS' do
      token = JWT.encode(payload, rsa_key, 'RS256', { kid: 'wrong_kid' })

      expect(described_class.new(access_token: token).invalid_reason).to eq(:unknown_key)
    end

    it 'is :expired for a token past its exp' do
      token = JWT.encode(payload.merge('exp' => Time.now.to_i - 3600), rsa_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).invalid_reason).to eq(:expired)
    end

    it 'is :invalid_issuer for the wrong iss' do
      token = JWT.encode(payload.merge('iss' => 'wrong_iss'), rsa_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).invalid_reason).to eq(:invalid_issuer)
    end

    it 'is :invalid_audience for the wrong aud' do
      token = JWT.encode(payload.merge('aud' => 'wrong_aud'), rsa_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).invalid_reason).to eq(:invalid_audience)
    end

    it 'is :jwks_unreachable when the JWKS endpoint cannot be reached' do
      allow(described_class).to receive(:fetch_jwks).and_raise(SocketError.new('getaddrinfo: Name or service not known'))
      allow(Sentry).to receive(:capture_exception_with_info)

      expect(helper.invalid_reason).to eq(:jwks_unreachable)
    end

    it 'covers every reason the class advertises' do
      expect(described_class::INVALID_REASONS).to contain_exactly(
        :missing, :malformed, :bad_signature, :unknown_key, :expired,
        :invalid_issuer, :invalid_audience, :jwks_unreachable
      )
    end

    # A wrong IDP_AUD locks out a whole deployment. The only evidence used to be the string
    # 'Invalid audience'.
    it 'reports expected and actual audience' do
      token = JWT.encode(payload.merge('aud' => 'wrong_aud'), rsa_key, 'RS256', { kid: kid })

      details = described_class.new(access_token: token).invalid_reason_details

      expect(details).to eq(reason: :invalid_audience, expected_audiences: ['test_aud'], actual_audience: 'wrong_aud')
    end

    it 'reports expected and actual issuer' do
      token = JWT.encode(payload.merge('iss' => 'wrong_iss'), rsa_key, 'RS256', { kid: kid })

      details = described_class.new(access_token: token).invalid_reason_details

      expect(details).to eq(reason: :invalid_issuer, expected_issuer: 'test_iss', actual_issuer: 'wrong_iss')
    end

    it 'reports the reason alone for a failure that names no expected value' do
      expect(described_class.new(access_token: 'not-a-jwt').invalid_reason_details).to eq(reason: :malformed)
    end

    # A request asks more than once, and re-running would re-log and re-report each time.
    it 'only works the reason out once' do
      bad_helper = described_class.new(access_token: 'not-a-jwt')

      expect(Rails.logger).to receive(:error).once

      2.times { bad_helper.invalid_reason }
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

    it '#last_name returns nil if only one name exists' do
      single_name_payload = payload.merge('name' => 'Cher')
      single_name_token = JWT.encode(single_name_payload, rsa_key, 'RS256', { kid: kid })
      single_name_helper = described_class.new(access_token: single_name_token)
      expect(single_name_helper.last_name).to be_nil
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
      described_class.new(access_token: access_token).valid?

      # Now validate a token signed with the rotated key
      rotated_helper = described_class.new(access_token: rotated_token)
      expect(rotated_helper.valid?).to be true
      expect(call_count).to eq(2)
    end

    it 'returns false after one retry for a genuinely unknown kid' do
      unknown_key = OpenSSL::PKey::RSA.generate(2048)
      unknown_token = JWT.encode(payload, unknown_key, 'RS256', { kid: 'never_in_jwks' })
      unknown_helper = described_class.new(access_token: unknown_token)

      expect(described_class).to receive(:fetch_jwks).twice.and_return(jwks_hash)
      expect(unknown_helper.valid?).to be false
    end
  end
end
