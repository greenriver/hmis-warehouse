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

  def initialize(access_token:)
    @access_token = access_token
  end

  def token?
    access_token.present?
  end

  def valid?
    return false unless token?

    unless public_key
      Rails.logger.info "Unable to find public key: #{header['kid']}"
      return false
    end

    payload
    true
  rescue JWT::ExpiredSignature
    Rails.logger.warn 'Token has expired'
    false
  rescue JWT::InvalidIssuerError
    Rails.logger.error 'Invalid issuer'
    false
  rescue JWT::InvalidAudError
    Rails.logger.error 'Invalid audience'
    false
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT verification failed: #{e.message}"
    false
  rescue JSON::ParserError => e
    Rails.logger.error "JSON verification failed: #{e.message}"
    false
  end

  memoize def payload
    JWT.decode(
      access_token,
      public_key,
      true,
      {
        algorithm: algorithm,
        aud: idp_audiences,
        iss: ENV.fetch('ISS_URL'),
        verify_aud: true,
        verify_iss: true,
      },
    )
  end

  private def idp_audiences
    ENV.fetch('IDP_AUD').split(',').map(&:strip)
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

  def last_login_at
    claims['iat']
  end

  def expiration_time
    exp = claims['exp']
    return nil unless exp

    Time.zone.at(exp)
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

  def self.assert_boot_config!
    missing = REQUIRED_ENV_KEYS.select { |key| ENV.fetch(key, '').blank? }
    raise "Missing JWT configuration: #{missing.join(', ')}" if missing.any?
  end

  # TODO: this is inconsistent based on the IDP
  def first_name
    claims['given_name'].to_s.strip.presence || claims['name'].to_s.strip.split.first&.titleize
  end

  # TODO: this is inconsistent based on the IDP
  def last_name
    raw = claims['name'].to_s.strip
    return nil if raw.blank?

    parts = raw.split
    return nil if parts.size <= 1

    parts.last.titleize
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

    def fetch_jwks
      uri = URI(ENV.fetch('JWKS_URL'))
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 5) do |http|
        http.get(uri.request_uri).body
      end
      JSON.parse(response)
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
