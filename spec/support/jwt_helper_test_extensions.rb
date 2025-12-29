# frozen_string_literal: true

# Test extensions for JwtHelper to support mock JWT tokens in system tests.
#
# This module is prepended to JwtHelper only when running system tests, keeping
# production code free of test-specific logic.
#
# Mock tokens follow the format: "mock-jwt-token-{user_id}-{random_hex}"
module JwtHelperTestExtensions
  # Override validate! to bypass cryptographic validation for mock tokens
  def validate!
    return false unless token?

    # In system tests, allow mock tokens to bypass validation
    if access_token.start_with?('mock-jwt-token-')
      return true
    end

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
    parts = access_token.split('-')
    user_id = parts[3] # "mock-jwt-token-{user_id}-..."
    user = User.find_by(id: user_id)
    [user_id, user&.email]
  end
end

# Prepend test extensions when running system tests
if Rails.env.test? && (ENV['RUN_SYSTEM_TESTS'] == 'true' || ENV['RUN_RAILS_SYSTEM_TESTS'] == 'true')
  JwtHelper.prepend(JwtHelperTestExtensions)
end
