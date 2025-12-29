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

    # For request specs: session will be initialized on first request
    # For controller specs: set up session
    if defined?(controller) && defined?(request) && request.present?
      # Ensure session is initialized for controller specs
      request.session # This access initializes the session
    end

    # Store token for use in headers
    @jwt_token = mock_token

    # For request specs: Override get/post/etc to inject headers
    # The integration_session is what actually makes requests, so we need to
    # wrap the HTTP methods to inject our JWT header
    jwt_header = { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => mock_token }

    # Store for any manual header access
    @jwt_headers = jwt_header

    # Detect if we're in a controller spec or request spec
    # Check the class hierarchy - controller specs include RSpec::Rails::ControllerExampleGroup
    # This is more reliable than metadata which may not be set up yet when sign_in is called
    is_controller_spec = self.class.ancestors.any? { |ancestor| ancestor.name == 'RSpec::Rails::ControllerExampleGroup' }

    # Fallback to metadata if class check doesn't work
    unless is_controller_spec
      if respond_to?(:example) && example.respond_to?(:metadata)
        is_controller_spec = example.metadata[:type] == :controller
      elsif respond_to?(:metadata)
        is_controller_spec = metadata[:type] == :controller
      end
    end

    test_instance = self

    if is_controller_spec
      # For controller specs: Stub controller methods before each HTTP request
      # Controller specs don't support custom :headers kwarg, so we stub current_user instead
      [:get, :post, :put, :patch, :delete, :head].each do |method|
        define_singleton_method(method) do |*args, **kwargs|
          # Stub current_user on controller if it exists
          if defined?(controller) && controller.present?
            allow(controller).to receive(:current_user).and_return(user)
            allow(controller).to receive(:user_signed_in?).and_return(true)
            # Also set headers on request object
            if defined?(request) && request.present?
              request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN'] = mock_token
            end
          end
          # Controller specs support standard Rails kwargs (params:, session:, etc.)
          # but not custom :headers kwarg
          super(*args, **kwargs)
        end
      end
    else
      # For request specs: Patch HTTP methods to include JWT headers and preserve session
      # Helper method to inject JWT and session headers, and preserve session cookies
      define_singleton_method(:inject_auth_headers_and_preserve_session) do |kwargs, spec_instance|
        # Merge JWT headers
        kwargs[:headers] = (kwargs[:headers] || {}).merge(spec_instance.instance_variable_get(:@jwt_headers) || {})
        # Preserve session cookie if it exists
        session_headers = spec_instance.instance_variable_get(:@session_headers)
        kwargs[:headers].merge!(session_headers) if session_headers
      end

      define_singleton_method(:store_session_cookie) do |spec_instance|
        # Store session cookie for next request
        # Handle both string and array values (multiple Set-Cookie headers)
        set_cookie = response.headers['Set-Cookie']
        return unless set_cookie

        cookie_value = set_cookie.is_a?(Array) ? set_cookie.join('; ') : set_cookie
        spec_instance.instance_variable_set(:@session_headers, { 'Cookie' => cookie_value })
      end

      # Override HTTP methods to include JWT headers and preserve session
      [:get, :post, :put, :patch, :delete, :head].each do |method|
        define_singleton_method(method) do |*args, **kwargs|
          inject_auth_headers_and_preserve_session(kwargs, test_instance)
          result = super(*args, **kwargs)
          store_session_cookie(test_instance)
          result
        end
      end

      # Override follow_redirect! to include JWT headers and preserve session
      # This is needed because follow_redirect! is delegated to integration_session
      # and its internal get() call doesn't go through our overridden get method
      define_singleton_method(:follow_redirect!) do |**kwargs|
        inject_auth_headers_and_preserve_session(kwargs, test_instance)
        result = super(**kwargs)
        store_session_cookie(test_instance)
        result
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
