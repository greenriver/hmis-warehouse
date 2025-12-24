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

    # Create authentication source upfront to avoid extra queries during request
    # This prevents ensure_authentication_source from running during the request
    user.user_authentication_sources.find_or_create_by!(
      connector_id: 'test',
      connector_user_id: user.id.to_s,
    ) do |auth_source|
      auth_source.enabled = true
    end
    user.update_column(:last_connector_id, 'test') if user.last_connector_id != 'test'

    # Store token for use in headers
    @jwt_token = mock_token

    # For request specs: Override get/post/etc to inject headers
    # The integration_session is what actually makes requests, so we need to
    # wrap the HTTP methods to inject our JWT header
    jwt_header = { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => mock_token }

    # Store for any manual header access
    @jwt_headers = jwt_header

    # For controller specs: Set headers on request object and stub current_user
    if defined?(controller) && controller.present?
      # Controller specs need headers set on the request object
      if defined?(request) && request.present?
        request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN'] = mock_token
      end
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
    else
      # For request specs: Patch HTTP methods to include JWT headers
      # This is called lazily when the first request is made
      test_instance = self

      # Use a before hook approach - define methods that add headers
      define_singleton_method(:get) do |*args, **kwargs|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(test_instance.instance_variable_get(:@jwt_headers) || {})
        super(*args, **kwargs)
      end

      define_singleton_method(:post) do |*args, **kwargs|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(test_instance.instance_variable_get(:@jwt_headers) || {})
        super(*args, **kwargs)
      end

      define_singleton_method(:put) do |*args, **kwargs|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(test_instance.instance_variable_get(:@jwt_headers) || {})
        super(*args, **kwargs)
      end

      define_singleton_method(:patch) do |*args, **kwargs|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(test_instance.instance_variable_get(:@jwt_headers) || {})
        super(*args, **kwargs)
      end

      define_singleton_method(:delete) do |*args, **kwargs|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(test_instance.instance_variable_get(:@jwt_headers) || {})
        super(*args, **kwargs)
      end

      define_singleton_method(:head) do |*args, **kwargs|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(test_instance.instance_variable_get(:@jwt_headers) || {})
        super(*args, **kwargs)
      end

      # Override follow_redirect! to include JWT headers
      # This is needed because follow_redirect! is delegated to integration_session
      # and its internal get() call doesn't go through our overridden get method
      define_singleton_method(:follow_redirect!) do |**kwargs|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(test_instance.instance_variable_get(:@jwt_headers) || {})
        super(**kwargs)
      end
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
  # Include for request specs - sign_in will dynamically override HTTP methods
  config.include JwtAuthenticationHelper, type: :request

  # Include for controller specs
  config.include JwtAuthenticationHelper, type: :controller
end
