###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::JwtHelper, :jwt_only do
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
      # A real IdP always stamps exp. Without it here every `valid? == true` example below would be
      # asserting the never-expires path, and #expiration_time would have nothing to read.
      'exp' => Time.now.to_i + 3600,
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

  # #valid? is `invalid_reason.nil?`. Per-reason cases belong under #invalid_reason; what belongs
  # here is the wiring in both directions plus the forgery attempts.
  describe '#valid?' do
    it 'returns true if token is valid' do
      expect(helper.valid?).to be true
    end

    it 'rejects a mismatched audience when IDP_AUD is blank (fail-closed)' do
      allow(ENV).to receive(:fetch).with('IDP_AUD').and_return('')
      bad_aud_payload = payload.merge('aud' => 'wrong_aud')
      bad_aud_token = JWT.encode(bad_aud_payload, rsa_key, 'RS256', { kid: kid })
      bad_aud_helper = described_class.new(access_token: bad_aud_token)
      expect(bad_aud_helper.valid?).to be false
    end

    # The signing algorithm is the whole basis of trust: every other example here signs with
    # JWT_ALGORITHM, so widening the allowlist passed to JWT.decode (adding 'none', or accepting a
    # symmetric alg) would forge tokens at will and leave the rest of this file green. These two pin
    # the allowlist to exactly the configured algorithm.
    it 'rejects an unsigned token even when its kid names a key we hold' do
      unsigned_token = JWT.encode(payload, nil, 'none', { kid: kid })
      unsigned_helper = described_class.new(access_token: unsigned_token)

      expect(unsigned_helper.valid?).to be false
      expect(unsigned_helper.invalid_reason).to eq(:malformed)
    end

    # Classic algorithm-substitution: sign with HMAC using the public key (which anyone can read
    # from the JWKS) as the shared secret, hoping the verifier treats it as the HMAC key.
    it 'rejects a token signed with a symmetric algorithm over our public key' do
      hmac_token = JWT.encode(payload, rsa_key.public_key.to_s, 'HS256', { kid: kid })
      hmac_helper = described_class.new(access_token: hmac_token)

      expect(hmac_helper.valid?).to be false
      expect(hmac_helper.invalid_reason).to eq(:malformed)
    end
  end

  # Lets a caller tell "nobody is signed in" apart from "our stack is misconfigured". #valid?
  # collapses both into false, which is why every caller guessed wrong.
  describe '#invalid_reason' do
    # The nil-for-a-good-token case is #valid?'s 'returns true if token is valid' above — valid? is
    # `invalid_reason.nil?`, so it is the same assertion read through the delegation.
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

    # ruby-jwt enforces exp only when the claim is present, so without required_claims this token
    # verifies at any point in the future and nothing on our side can revoke it.
    it 'is :malformed for a token carrying no exp claim' do
      token = JWT.encode(payload.except('exp'), rsa_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).invalid_reason).to eq(:malformed)
    end

    # The :invalid_issuer and :invalid_audience reasons are asserted by the invalid_reason_details
    # examples below, which carry `reason:` in the hash they compare.

    # Sentry is asserted here because an unreachable IdP is the one reason that means our stack is
    # broken rather than the caller's token, and nothing else in the request would say so.
    it 'is :jwks_unreachable when the JWKS endpoint cannot be reached, and reports to Sentry' do
      allow(described_class).to receive(:fetch_jwks).and_raise(SocketError.new('getaddrinfo: Name or service not known'))
      expect(Sentry).to receive(:capture_exception_with_info).with(instance_of(SocketError), anything)

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

  # This is the key User.find_from_jwt matches on, so every normalization here decides which account
  # a token resolves to. Dropping the strip would provision a second account for the same person;
  # dropping the presence would hand a blank string to the lookup.
  describe '#payload_email' do
    it 'returns downcased email from payload' do
      expect(helper.payload_email).to eq('test@example.com')
    end

    it 'strips surrounding whitespace before downcasing' do
      token = JWT.encode(payload.merge('email' => "  Pad@Example.COM \n"), rsa_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).payload_email).to eq('pad@example.com')
    end

    it 'is nil rather than a blank string when the claim is whitespace only' do
      token = JWT.encode(payload.merge('email' => '   '), rsa_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).payload_email).to be_nil
    end

    it 'is nil when the claim is absent' do
      token = JWT.encode(payload.except('email'), rsa_key, 'RS256', { kid: kid })

      expect(described_class.new(access_token: token).payload_email).to be_nil
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

  # These three class methods are the only auth-gate this class exposes to Idp::JwtApiController
  # and ApplicationCable::Connection. Elsewhere in the suite (e.g. warehouse_jwt_wiring_spec.rb)
  # Idp::JwtHelper itself is stubbed away, so nothing else runs a real token through
  # User.find_from_jwt for these three entry points — these do, end to end.
  describe '.authenticated?' do
    it 'is true for a token that verifies' do
      expect(described_class.authenticated?(access_token)).to be true
    end

    it 'is false for a token that fails verification' do
      bad_signature_token = JWT.encode(payload, OpenSSL::PKey::RSA.generate(2048), 'RS256', { kid: kid })

      expect(described_class.authenticated?(bad_signature_token)).to be false
    end

    it 'is false when there is no token' do
      expect(described_class.authenticated?(nil)).to be false
    end
  end

  describe '.user_id_from_token' do
    it 'is nil when there is no token' do
      expect(described_class.user_id_from_token(nil)).to be_nil
    end

    it 'is nil for a token that fails verification' do
      bad_signature_token = JWT.encode(payload, OpenSSL::PKey::RSA.generate(2048), 'RS256', { kid: kid })

      expect(described_class.user_id_from_token(bad_signature_token)).to be_nil
    end

    it 'is nil when no user matches the resolved identity' do
      expect(described_class.user_id_from_token(access_token)).to be_nil
    end

    it 'is the id of the user the token resolves to' do
      user = create(:user, email: 'test@example.com')

      expect(described_class.user_id_from_token(access_token)).to eq(user.id)
    end
  end

  describe '.active_user_from_token' do
    it 'is nil for a token that fails verification' do
      bad_signature_token = JWT.encode(payload, OpenSSL::PKey::RSA.generate(2048), 'RS256', { kid: kid })

      expect(described_class.active_user_from_token(bad_signature_token)).to be_nil
    end

    it 'is nil when no user matches the resolved identity' do
      expect(described_class.active_user_from_token(access_token)).to be_nil
    end

    it 'is the resolved user when active' do
      user = create(:user, email: 'test@example.com', active: true)

      expect(described_class.active_user_from_token(access_token)).to eq(user)
    end

    it 'is nil when the resolved user is deactivated' do
      create(:user, email: 'test@example.com', active: false)

      expect(described_class.active_user_from_token(access_token)).to be_nil
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

    # The other half of this guard. A typo'd AUTH_METHOD doesn't fail loudly on its own: AuthMethod
    # .jwt? just comes back false and the app quietly boots on Devise with the JWT stack inert. This
    # raise is what turns that into a failed deploy, so it needs its own example.
    describe 'AUTH_METHOD' do
      before { allow(ENV).to receive(:[]).and_call_original }

      it 'raises naming the offending value when AUTH_METHOD is not recognized' do
        allow(ENV).to receive(:[]).with('AUTH_METHOD').and_return('jwtt')

        expect { described_class.assert_boot_config! }.to raise_error(RuntimeError, /Invalid AUTH_METHOD.*jwtt/)
      end

      ['jwt', 'devise', nil].each do |auth_method|
        it "accepts #{auth_method.inspect}" do
          allow(ENV).to receive(:[]).with('AUTH_METHOD').and_return(auth_method)

          expect { described_class.assert_boot_config! }.not_to raise_error
        end
      end
    end
  end

  # Every other example in this file stubs .fetch_jwks, so the one method that decides which keys we
  # trust was never exercised. These drive the real Net::HTTP path against WebMock.
  describe '.fetch_jwks' do
    let(:jwks_url) { 'https://idp.example.test/jwks' }

    before { allow(described_class).to receive(:fetch_jwks).and_call_original }

    it 'parses the keyset served by JWKS_URL' do
      request = stub_request(:get, jwks_url).
        to_return(body: jwks_hash.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.fetch_jwks).to eq(jwks_hash)
      expect(request).to have_been_requested
    end

    # Not a style point: Net::HTTP defaults to no read timeout, so a wedged IdP would hang every
    # authenticated request in the pool instead of failing closed via NETWORK_ERRORS.
    it 'bounds both the connect and the read' do
      stub_request(:get, jwks_url).to_return(body: jwks_hash.to_json)

      expect(Net::HTTP).to receive(:start).
        with('idp.example.test', 443, hash_including(use_ssl: true, open_timeout: 5, read_timeout: 5)).
        and_call_original

      described_class.fetch_jwks
    end

    # The existing SocketError example hand-raises the exception. This one proves NETWORK_ERRORS
    # actually names what Net::HTTP raises on a real stall, which a hand-raised error cannot.
    it 'surfaces a transport stall as :jwks_unreachable rather than a client-token problem' do
      stub_request(:get, jwks_url).to_timeout
      allow(Sentry).to receive(:capture_exception_with_info)

      expect(helper.invalid_reason).to eq(:jwks_unreachable)
    end

    # 200 with a non-JSON body: the status check alone would miss this one.
    it 'surfaces a 200 with an unparseable body as :jwks_unreachable' do
      stub_request(:get, jwks_url).to_return(status: 200, body: 'not json')
      expect(Sentry).to receive(:capture_exception_with_info).
        with(instance_of(described_class::JwksUnavailableError), anything)

      expect(helper.invalid_reason).to eq(:jwks_unreachable)
    end

    # 200 with well-formed JSON that isn't a keyset — a gateway answering {"error": ...} without
    # bothering to set a status. Neither the status check nor the parse guard catches this shape;
    # unguarded it raises NoMethodError out of #invalid_reason instead of failing closed.
    [
      ['a keyless object', '{"foo":"bar"}'],
      ['keys that are not an array', '{"keys":"nope"}'],
      ['a bare array', '[]'],
      ['a JSON literal', 'null'],
    ].each do |shape, body|
      it "surfaces #{shape} from the JWKS endpoint as :jwks_unreachable" do
        stub_request(:get, jwks_url).
          to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
        expect(Sentry).to receive(:capture_exception_with_info).
          with(instance_of(described_class::JwksUnavailableError), anything)

        expect(helper.invalid_reason).to eq(:jwks_unreachable)
      end
    end

    # A failed fetch must not poison the hour-long JWKS cache — otherwise one bad response keeps
    # rejecting good tokens long after the IdP recovers. The keyless 200 is the dangerous shape: it
    # looks like a successful fetch, so nothing but the raise keeps it out of memory_cache.
    [
      ['a 502 with an HTML body', 502, '<html>bad gateway</html>'],
      ['a 200 with an error object', 200, '{"error":"service unavailable"}'],
    ].each do |shape, status, body|
      it "does not cache #{shape}" do
        stub_request(:get, jwks_url).to_return(status: status, body: body)
        allow(Sentry).to receive(:capture_exception_with_info)
        expect(helper.invalid_reason).to eq(:jwks_unreachable)
        expect(described_class.memory_cache.read('jwt_helper_jwks')).to be_nil

        stub_request(:get, jwks_url).
          to_return(body: jwks_hash.to_json, headers: { 'Content-Type' => 'application/json' })

        expect(described_class.new(access_token: access_token).invalid_reason).to be_nil
      end
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
