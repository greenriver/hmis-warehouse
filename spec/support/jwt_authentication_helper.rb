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
  # When prepended, these methods are called before ActionDispatch::IntegrationTest's methods
  [:get, :post, :put, :patch, :delete, :head].each do |method|
    define_method(method) do |path, *args, **kwargs|
      # Merge JWT headers if available
      if instance_variable_defined?(:@jwt_headers) && @jwt_headers.present?
        kwargs[:headers] ||= {}
        # Merge JWT headers
        kwargs[:headers] = kwargs[:headers].merge(@jwt_headers)
      end
      # Call super to use the original method from ActionDispatch::IntegrationTest
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
      expiration_time: 1.hour.from_now,
    )

    # Stub JwtHelper.authenticated? class method
    # Returns true for mock token, calls original for other tokens
    allow(JwtHelper).to receive(:authenticated?).and_wrap_original do |original_method, token|
      token == mock_token ? true : original_method.call(token)
    end

    # Stub JwtHelper.user_id_from_token class method
    # Returns user.id for mock token, calls original for other tokens
    allow(JwtHelper).to receive(:user_id_from_token).and_wrap_original do |original_method, token|
      token == mock_token ? user.id : original_method.call(token)
    end

    # Stub JwtHelper.new to return our mock helper for the mock token
    # Calls original for other tokens
    allow(JwtHelper).to receive(:new).and_wrap_original do |original_method, **kwargs|
      kwargs[:access_token] == mock_token ? jwt_helper : original_method.call(**kwargs)
    end

    # Stub User.find_from_jwt to return the user for our mock helper
    # Calls original for other helpers
    allow(User).to receive(:find_from_jwt).and_wrap_original do |original_method, helper|
      helper == jwt_helper ? user : original_method.call(helper)
    end

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

  # Get the mock JWT token for the signed-in user.
  #
  # @return [String, nil] The mock JWT token or nil if not signed in
  def jwt_token
    @jwt_token
  end
end

RSpec.configure do |config|
  # Include the module for sign_in and other helper methods
  config.include JwtAuthenticationHelper, type: :request
  config.include JwtAuthenticationHelper, type: :controller

  # Prepend to the example's singleton class AFTER example group before blocks run
  # This ensures sign_in has been called and @jwt_headers is set
  config.append_before(:each, type: :request) do |example|
    # Prepend to ensure our method overrides take precedence
    example.singleton_class.prepend(JwtAuthenticationHelper) unless example.singleton_class.ancestors.include?(JwtAuthenticationHelper)
  end
end
