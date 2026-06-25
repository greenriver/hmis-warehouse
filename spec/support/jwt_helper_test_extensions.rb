###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Plumbing for future JWT system/request test support.
# Not yet wired up — will be used when spec/support/jwt_authentication_helper.rb is implemented.
#
# Prepended to Idp::JwtHelper only when running tests, keeping production code
# free of test-specific logic.
# See also: config/initializers/test_jwt_middleware.rb (cookie-to-header transport)
#
# Mock tokens follow the format: "mock-jwt-token-{user_id}-{random_hex}"
module JwtHelperTestExtensions
  # Override valid? to bypass cryptographic validation for mock tokens
  def valid?
    return false unless token?

    # In system tests, allow mock tokens to bypass validation
    return true if access_token.start_with?('mock-jwt-token-')

    # Call original implementation for real tokens
    super
  end

  # Override payload to return mock payload for mock tokens
  def payload
    # For mock tokens in system tests, return mock payload
    if access_token.start_with?('mock-jwt-token-')
      user_id, email = extract_mock_token_data
      now = Time.current.to_i
      return [
        {
          'email' => email || 'test@example.com',
          'federated_claims' => {
            'connector_id' => 'test',
            'user_id' => user_id,
          },
          'iat' => now,
          'exp' => now + 3600, # 1 hour expiration for system tests
        },
        {},
      ]
    end

    # Call original implementation for real tokens
    super
  end

  private

  # Extracts user ID and email from mock token format: "mock-jwt-token-{user_id}-{random_hex}"
  def extract_mock_token_data
    match = access_token.match(/\Amock-jwt-token-(?<user_id>\d+)-/)
    user_id = match[:user_id]
    user = User.find_by(id: user_id)
    [user_id, user&.email]
  end
end

# Prepend test extensions when running any tests (controller specs, request specs, system tests)
Idp::JwtHelper.prepend(JwtHelperTestExtensions) if Rails.env.test?
