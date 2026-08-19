###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/http'
require 'memery'

# Checks that an incoming login token is genuine and reads the user details out of it.
class Idp::JwtHelper
  include Memery
  attr_reader :access_token

  REQUIRED_ENV_KEYS = ['IDP_AUD', 'ISS_URL', 'JWKS_URL', 'JWT_ALGORITHM'].freeze
  VALID_AUTH_METHODS = [nil, 'devise', 'jwt'].freeze

  # :missing is the only one that's routinely legitimate — see skip_auth_routes in the proxy config.
  INVALID_REASONS = [
    :missing,
    :malformed,
    :bad_signature,
    :unknown_key,
    :expired,
    :invalid_issuer,
    :invalid_audience,
    :jwks_unreachable,
  ].freeze

  # The JWKS endpoint answered, but with something that isn't a keyset: an error status, or a body
  # we can't use (a proxy's HTML error page, say). Handled alongside NETWORK_ERRORS.
  class JwksUnavailableError < StandardError; end

  # Transport-level failures reaching JWKS_URL. We can't verify the token when the IdP is
  # unreachable, so we fail closed
  NETWORK_ERRORS = [
    SocketError,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::ETIMEDOUT,
    Net::OpenTimeout,
    Net::ReadTimeout,
    OpenSSL::SSL::SSLError,
    Timeout::Error,
  ].freeze

  def initialize(access_token:)
    @access_token = access_token
  end

  def token?
    access_token.present?
  end

  def valid?
    invalid_reason.nil?
  end

  # Why the token didn't verify, nil when it did. A refused forwarded token means our stack is
  # broken; a refused bearer token just means a wrong client. valid? can't tell those apart.
  # Memoized because callers ask more than once and this logs.
  #
  # @return [Symbol, nil] one of INVALID_REASONS
  memoize def invalid_reason
    return :missing unless token?

    # Header first: a token we can't parse is malformed without fetching a keyset to find out.
    header

    unless public_key
      Rails.logger.info "Unable to find public key: #{header['kid']}"
      return :unknown_key
    end

    payload
    nil
  rescue JWT::ExpiredSignature
    Rails.logger.warn 'Token has expired'
    :expired
  rescue JWT::InvalidIssuerError
    Rails.logger.error "Invalid issuer: expected #{expected_issuer.inspect}, token carried #{actual_issuer.inspect}"
    :invalid_issuer
  rescue JWT::InvalidAudError
    Rails.logger.error "Invalid audience: expected one of #{expected_audiences.inspect}, token carried #{actual_audience.inspect}"
    :invalid_audience
  # Ahead of JWT::DecodeError, which it subclasses.
  rescue JWT::VerificationError => e
    Rails.logger.error "JWT signature verification failed: #{e.message}"
    :bad_signature
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT verification failed: #{e.message}"
    :malformed
  rescue JSON::ParserError => e
    Rails.logger.error "JSON verification failed: #{e.message}"
    :malformed
  rescue JwksUnavailableError, *NETWORK_ERRORS => e
    Rails.logger.error "JWT verification could not get a keyset from the JWKS endpoint: #{e.message}"
    Sentry.capture_exception_with_info(e, 'JWT verification could not get a keyset from the JWKS endpoint; treating token as invalid')
    :jwks_unreachable
  end

  # Detail for the Sentry `extra`/`info` hash. Never the token itself.
  def invalid_reason_details
    reason = invalid_reason
    details = { reason: reason }
    case reason
    when :invalid_issuer
      details.merge(expected_issuer: expected_issuer, actual_issuer: actual_issuer)
    when :invalid_audience
      details.merge(expected_audiences: expected_audiences, actual_audience: actual_audience)
    else
      details
    end
  end

  # required_claims: ruby-jwt enforces exp only when the claim is present, so a token carrying none
  # would verify forever — iss/aud don't bound a lifetime. A token without exp is :malformed.
  memoize def payload
    JWT.decode(
      access_token,
      public_key,
      true,
      {
        algorithm: algorithm,
        aud: idp_audiences,
        iss: ENV.fetch('ISS_URL'),
        required_claims: ['exp'],
        verify_aud: true,
        verify_iss: true,
      },
    )
  end

  private def idp_audiences
    ENV.fetch('IDP_AUD').split(',').map(&:strip)
  end

  private def expected_issuer
    ENV.fetch('ISS_URL')
  end

  private def expected_audiences
    idp_audiences
  end

  private def actual_issuer
    unverified_claims['iss']
  end

  private def actual_audience
    unverified_claims['aud']
  end

  # Error messages only — nothing here has been verified, so don't act on it.
  private def unverified_claims
    JWT.decode(access_token, nil, false, algorithm: algorithm).first
  rescue StandardError
    {}
  end

  # JWT.decode returns [claims, header]; this is the claims half.
  private def claims
    payload.first
  end

  def connector_user_id
    claims.dig('federated_claims', 'user_id')
  end
  alias_method :idp_user, :connector_user_id

  def connector_id
    claims.dig('federated_claims', 'connector_id')
  end
  alias_method :idp, :connector_id

  def payload_email
    claims['email'].to_s.strip.downcase.presence
  end

  def email_verified
    raw = claims['email_verified']
    return nil if raw.nil?

    ActiveModel::Type::Boolean.new.cast(raw)
  end

  def last_login_at
    claims['iat']
  end

  # Never nil for a token that verified: #payload requires the exp claim.
  def expiration_time
    Time.zone.at(claims['exp'])
  end

  # Returns the at_hash claim — stable per token, changes on reissue.
  # Not all IdPs include at_hash in access tokens; callers must handle nil.
  def session_id
    claims['at_hash']
  end

  def self.authenticated?(access_token)
    return false unless access_token.present?

    helper = new(access_token: access_token)
    helper.token? && helper.valid?
  end

  # User.find_from_jwt is provided by L1.2 (idp-l1-identity-resolution); inert until then.
  def self.user_id_from_token(access_token)
    return nil unless access_token.present?

    helper = new(access_token: access_token)
    return nil unless helper.token? && helper.valid?

    User.find_from_jwt(helper)&.id
  end

  # Resolves an active user from a token, without provisioning or any other side effect
  def self.active_user_from_token(access_token)
    helper = new(access_token: access_token)
    return nil unless helper.valid?

    user = User.find_from_jwt(helper)
    user if user&.active?
  end

  def self.assert_boot_config!
    auth_method = ENV['AUTH_METHOD']
    raise "Invalid AUTH_METHOD: #{auth_method.inspect}" unless VALID_AUTH_METHODS.include?(auth_method)

    missing = REQUIRED_ENV_KEYS.select { |key| ENV.fetch(key, '').blank? }
    raise "Missing JWT configuration: #{missing.join(', ')}" if missing.any?
  end

  def first_name
    claims['given_name'].to_s.strip.presence || name_parts.first
  end

  def last_name
    claims['family_name'].to_s.strip.presence || name_parts.drop(1).join(' ').presence
  end

  private def name_parts
    @name_parts ||= claims['name'].to_s.split
  end

  def jwks
    self.class.jwks
  end

  class << self
    def jwks
      memory_cache.fetch('jwt_helper_jwks', expires_in: 1.hour) do
        fetch_jwks
      end
    end

    # Raises rather than returns anything that isn't a keyset: only a raise reaches the fail-closed
    # rescue in #invalid_reason, and only a raise keeps the bad response out of memory_cache.
    def fetch_jwks
      uri = URI(ENV.fetch('JWKS_URL'))
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 5) do |http|
        http.get(uri.request_uri)
      end
      raise JwksUnavailableError, "JWKS endpoint returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      keyset = begin
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError => e
        raise JwksUnavailableError, "JWKS endpoint returned an unparseable body: #{e.message}"
      end
      # Well-formed JSON that still isn't a keyset, such as a gateway's {"error": ...}
      keys = keyset['keys'] if keyset.is_a?(Hash)
      raise JwksUnavailableError, "JWKS endpoint returned no keys: #{keyset.class}" unless keys.is_a?(Array) && keys.any?

      keyset
    end

    def invalidate_jwks_cache!
      memory_cache.delete('jwt_helper_jwks')
    end

    def memory_cache
      @memory_cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end

  memoize private def header
    JWT.decode(access_token, nil, false, algorithm: algorithm)[1]
  end

  # Looks up the public key for this token's kid. On a cache miss (key rotation),
  # busts the JWKS cache and retries once before giving up.
  private def public_key
    find_public_key(allow_retry: true)
  end

  private def find_public_key(allow_retry:)
    key_data = jwks['keys'].find { |key| key['kid'] == header['kid'] }

    if key_data.nil? && allow_retry
      self.class.invalidate_jwks_cache!
      return find_public_key(allow_retry: false)
    end

    return nil unless key_data

    JWT::JWK.import(key_data).keypair
  end

  private def algorithm
    ENV.fetch('JWT_ALGORITHM')
  end
end
