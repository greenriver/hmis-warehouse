###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/http'

# Provides a friendly interface JWTs (JSON Web Tokens).
#
# This class:
# * fetches the public key from a JWKS endpoint
# * uses the key to validate the signature of a given JWT access token
# * verifies claims such as issuer and audience
# * wraps some known patterns for fetching email and name from the JWT
#
# @example Validate a JWT token
#   helper = JwtHelper.new(access_token: request.headers["HTTP_X_FORWARDED_ACCESS_TOKEN"])
#   valid = helper.validate! # => true or false
class JwtHelper
  include Memery
  attr_accessor :access_token

  # Initializes the JwtHelper instance with an access token.
  #
  # @param access_token [String] The JWT token to be verified.
  def initialize(access_token:)
    @access_token = access_token
  end

  def token?
    access_token.present?
  end

  # Validates the JWT token by checking its signature and claims.
  #
  # @return [Boolean] true if the token is valid, false otherwise.
  # @raise [RuntimeError] if the public key cannot be found for the given "kid".
  def validate!
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
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT verification failed: #{e.message}"
    false
  rescue JSON::ParserError => e
    Rails.logger.error "JSON verification failed: #{e.message}"
    false
  end

  # Decodes and returns the JWT payload.
  #
  # @return [Array<Hash, Hash>] The decoded JWT payload and header.
  # @raise [JWT::DecodeError] if the token cannot be decoded.
  memoize def payload
    JWT.decode(
      access_token,
      public_key,
      true, # verify signature
      {
        algorithm: algorithm,
        aud: idp_audiences,
        iss: ENV.fetch('ISS_URL'),
        verify_aud: ENV.fetch('IDP_AUD').present?,
        verify_iss: ENV.fetch('ISS_URL').present?,
      },
    )
  end

  # Returns the list of valid audience values for JWT validation.
  # Supports both single value and comma-separated list from IDP_AUD env var.
  # Defaults to both hmis-warehouse and hmis-frontend if not set.
  #
  # @return [Array<String>] List of valid audience values
  private def idp_audiences
    aud = ENV.fetch('IDP_AUD', 'hmis-warehouse,hmis-frontend,superset')
    aud.split(',').map(&:strip)
  end

  def email(forwarded_email)
    return false unless payload_email == forwarded_email.to_s.downcase

    payload_email
  end

  def connector_user_id
    payload.first.dig('federated_claims', 'user_id') || payload_email
  end
  alias_method :idp_user, :connector_user_id

  def connector_id
    payload.first.dig('federated_claims', 'connector_id') || 'unknown'
  end
  alias_method :idp, :connector_id

  memoize def payload_email
    payload.first['email'].to_s.downcase
  end

  def last_login_at
    payload.first['iat']
  end

  # Get token expiration time.
  #
  # Returns the expiration time from the JWT's 'exp' claim.
  # Standard JWT tokens include an 'exp' claim indicating when the token expires.
  # Returns the time in the application's configured timezone.
  #
  # @return [Time, nil] Expiration time as a Time object in the application timezone, or nil if not present
  def expiration_time
    exp = payload.first['exp']
    return nil unless exp

    Time.zone.at(exp)
  end

  # Get the access token hash from the token.
  #
  # The 'at_hash' claim is a hash of the access token and changes with each new token issued.
  # It remains constant across requests using the same token, making it ideal for session tracking.
  # Used for token denylist/blacklist tracking to invalidate specific tokens.
  #
  # @return [String, nil] The access token hash, or nil if not available
  def session_id
    payload.first['at_hash']
  end

  # Check if an access token represents an authenticated user.
  #
  # This is a lightweight check that validates the token exists and is valid.
  # Used by middleware like Rack::Attack to determine authentication status.
  #
  # @param access_token [String, nil] The JWT access token
  # @return [Boolean] true if token is present and valid, false otherwise
  def self.authenticated?(access_token)
    return false unless access_token.present?

    helper = new(access_token: access_token)
    helper.token? && helper.validate!
  end

  # Get user ID from an access token.
  #
  # Validates the token and returns the associated user's ID.
  # Returns nil if token is invalid or user cannot be found.
  #
  # @param access_token [String, nil] The JWT access token
  # @return [Integer, nil] User ID or nil if not found/invalid
  def self.user_id_from_token(access_token)
    return nil unless access_token.present?

    helper = new(access_token: access_token)
    return nil unless helper.token? && helper.validate!

    User.find_from_jwt(helper)&.id
  end

  # TODO: this is inconsistent based on the IDP
  def first_name
    payload.first['given_name'].presence || payload.first['name'].strip.split.first.titleize
  end

  # TODO: this is inconsistent based on the IDP
  def last_name
    name = payload.first['name'].strip.split.last
    name == payload.first['name'].strip ? '' : name.titleize
  end

  # Fetches the JSON Web Key Set (JWKS) from the configured endpoint.
  #
  # @return [Hash] The parsed JSON response containing public keys.
  # @raise [JSON::ParserError] if the response is not valid JSON.
  def jwks
    self.class.jwks
  end

  class << self
    def jwks
      memory_cache.fetch('jwt_helper_jwks', expires_in: 1.hour) do
        uri = URI(ENV.fetch('JWKS_URL'))
        response = Net::HTTP.get(uri)
        JSON.parse(response)
      end
    end

    def memory_cache
      @memory_cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end

  # Extracts and returns the JWT header.
  #
  # @return [Hash] The JWT header containing metadata like algorithm and key ID.
  # @raise [JWT::DecodeError] if the token header cannot be decoded.
  memoize private def header
    JWT.decode(access_token, nil, false, algorithm: algorithm)[1]
  end

  # Retrieves the public key associated with the JWT's "kid" from the JWKS response.
  #
  # @return [OpenSSL::PKey::RSA, nil] The public RSA key or nil if no matching key is found.
  memoize private def public_key
    key_data = jwks['keys'].find { |key| key['kid'] == header['kid'] }
    return nil unless key_data

    JWT::JWK.import(key_data).keypair
  end

  # Retrieves the expected JWT algorithm from environment variables.
  #
  # @return [String] The JWT algorithm (e.g., "RS256").
  private def algorithm
    ENV.fetch('JWT_ALGORITHM')
  end
end
