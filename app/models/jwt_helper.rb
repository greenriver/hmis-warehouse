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
        aud: ENV.fetch('IDP_AUD'),
        iss: ENV.fetch('ISS_URL'),
      },
    )
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

  # TODO: this is inconsistent based on the IDP
  def first_name
    payload.first['name'].strip.split.first.titleize
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
  memoize private def jwks
    uri = URI(ENV.fetch('JWKS_URL'))
    response = Net::HTTP.get(uri)
    JSON.parse(response)
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

    # Inspired by: https://stackoverflow.com/questions/77209118/creating-rsa-key-with-openssl-v3-using-modulus-and-exponent-doesnt-work-in
    data_sequence = OpenSSL::ASN1::Sequence(
      [
        OpenSSL::ASN1::Integer(base64_to_long(key_data['n'])),
        OpenSSL::ASN1::Integer(base64_to_long(key_data['e'])),
      ],
    )
    asn_1 = OpenSSL::ASN1::Sequence(data_sequence)
    OpenSSL::PKey::RSA.new(asn_1.to_der)
  end

  private def base64_to_long(data)
    decoded_with_padding = Base64.urlsafe_decode64(data) + Base64.decode64('==')
    decoded_with_padding.to_s.unpack('C*').map do |byte|
      byte_to_hex(byte)
    end.join.to_i(16)
  end

  private def byte_to_hex(int)
    int < 16 ? "0#{int.to_s(16)}" : int.to_s(16)
  end

  # Retrieves the expected JWT algorithm from environment variables.
  #
  # @return [String] The JWT algorithm (e.g., "RS256").
  private def algorithm
    ENV.fetch('JWT_ALGORITHM')
  end
end
