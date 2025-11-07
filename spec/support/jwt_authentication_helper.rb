###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Helper methods for JWT authentication in tests.
#
# Provides a `sign_in` method compatible with request specs that sets up
# JWT authentication by stubbing JWT validation and setting request headers.
module JwtAuthenticationHelper
  # Override request methods to automatically include JWT headers
  [:get, :post, :put, :patch, :delete, :head].each do |method|
    define_method(method) do |path, *args, **kwargs|
      # Merge JWT headers if available
      if instance_variable_defined?(:@jwt_headers) && @jwt_headers.present?
        kwargs[:headers] ||= {}
        # Merge JWT headers
        kwargs[:headers] = kwargs[:headers].merge(@jwt_headers)
      end
      # Call super with all arguments
      super(path, *args, **kwargs)
    end
  end

  # Sign in a user for request specs using JWT authentication.
  #
  # Sets up stubs so that JWT validation returns the given user.
  # Stores the mock token for use in request headers.
  #
  # @param user [User, Hmis::User] The user to sign in
  # @return [String] The mock JWT token used for authentication
  def sign_in(user)
    # Generate a unique mock token for this user
    mock_token = "mock-jwt-token-#{user.id}-#{SecureRandom.hex(8)}"

    # Stub JwtHelper to validate the token and return user
    jwt_helper = instance_double(
      JwtHelper,
      token?: true,
      validate!: true,
      connector_id: 'test',
      connector_user_id: user.id.to_s,
      payload_email: user.email,
    )

    # Stub JwtHelper.authenticated? class method
    allow(JwtHelper).to receive(:authenticated?).with(mock_token).and_return(true)
    allow(JwtHelper).to receive(:authenticated?).and_call_original

    # Stub JwtHelper.user_id_from_token class method
    allow(JwtHelper).to receive(:user_id_from_token).with(mock_token).and_return(user.id)
    allow(JwtHelper).to receive(:user_id_from_token).and_call_original

    # Stub JwtHelper.new to return our mock helper
    allow(JwtHelper).to receive(:new).with(access_token: mock_token).and_return(jwt_helper)
    allow(JwtHelper).to receive(:new).and_call_original

    # Stub User.find_from_jwt to return the user
    allow(User).to receive(:find_from_jwt).with(jwt_helper).and_return(user)
    allow(User).to receive(:find_from_jwt).and_call_original

    # Store token for use in headers
    @jwt_token = mock_token
    @jwt_headers = { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => mock_token }

    # For controller specs: stub current_user
    if defined?(controller) && controller.present?
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end

    mock_token
  end

  # Get JWT authentication headers for use in request specs.
  #
  # Use this when you need to explicitly pass headers to requests:
  #   get path, headers: jwt_headers
  #
  # @return [Hash] Headers hash with JWT token
  def jwt_headers
    @jwt_headers ||= {}
  end

  # Get the mock JWT token for the signed-in user.
  #
  # @return [String, nil] The mock JWT token or nil if not signed in
  def jwt_token
    @jwt_token
  end
end

RSpec.configure do |config|
  config.include JwtAuthenticationHelper, type: :request
  config.include JwtAuthenticationHelper, type: :controller
end
