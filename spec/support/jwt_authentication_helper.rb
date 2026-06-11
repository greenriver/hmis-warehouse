###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module JwtAuthenticationHelper
  def sign_in(user)
    mock_token = "mock-jwt-token-#{user.id}-#{SecureRandom.hex(8)}"
    mock_session_id = "mock-session-id-#{user.id}-#{SecureRandom.hex(4)}"

    jwt_helper = instance_double(
      JwtHelper,
      token?: true,
      valid?: true,
      connector_id: 'test',
      connector_user_id: user.id.to_s,
      payload_email: user.email,
      expiration_time: 1.hour.from_now,
      session_id: mock_session_id,
    )

    allow(JwtHelper).to receive(:authenticated?).and_wrap_original do |original_method, token|
      token == mock_token ? true : original_method.call(token)
    end

    allow(JwtHelper).to receive(:user_id_from_token).and_wrap_original do |original_method, token|
      token == mock_token ? user.id : original_method.call(token)
    end

    allow(JwtHelper).to receive(:new).and_wrap_original do |original_method, **kwargs|
      kwargs[:access_token] == mock_token ? jwt_helper : original_method.call(**kwargs)
    end

    allow(User).to receive(:find_from_jwt).and_wrap_original do |original_method, helper|
      helper == jwt_helper ? user : original_method.call(helper)
    end

    user.user_authentication_sources.find_or_create_by!(
      connector_id: 'test',
      connector_user_id: user.id.to_s,
    )
    user.update_column(:last_connector_id, 'test') if user.last_connector_id != 'test'

    if defined?(controller) && defined?(request) && request.present?
      request.session
    end

    @jwt_token = mock_token
    @jwt_session_id = mock_session_id

    jwt_header = { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => mock_token }
    @jwt_headers = jwt_header

    is_controller_spec = self.class.ancestors.any? { |ancestor| ancestor.name == 'RSpec::Rails::ControllerExampleGroup' }

    unless is_controller_spec
      if respond_to?(:example) && example.respond_to?(:metadata)
        is_controller_spec = example.metadata[:type] == :controller
      elsif respond_to?(:metadata)
        is_controller_spec = metadata[:type] == :controller
      end
    end

    test_instance = self

    if is_controller_spec
      if defined?(controller) && controller.present?
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        if defined?(request) && request.present?
          request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN'] = mock_token
        end
      end

      [:get, :post, :put, :patch, :delete, :head].each do |method|
        define_singleton_method(method) do |*args, **kwargs|
          if defined?(controller) && controller.present?
            allow(controller).to receive(:current_user).and_return(user)
            allow(controller).to receive(:user_signed_in?).and_return(true)
            if defined?(request) && request.present?
              request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN'] = mock_token
            end
          end
          super(*args, **kwargs)
        end
      end
    else
      define_singleton_method(:inject_auth_headers_and_preserve_session) do |kwargs, spec_instance|
        kwargs[:headers] = (kwargs[:headers] || {}).merge(spec_instance.instance_variable_get(:@jwt_headers) || {})
        session_headers = spec_instance.instance_variable_get(:@session_headers)
        kwargs[:headers].merge!(session_headers) if session_headers
      end

      define_singleton_method(:store_session_cookie) do |spec_instance|
        set_cookie = response.headers['Set-Cookie']
        return unless set_cookie

        cookie_value = set_cookie.is_a?(Array) ? set_cookie.join('; ') : set_cookie
        spec_instance.instance_variable_set(:@session_headers, { 'Cookie' => cookie_value })
      end

      [:get, :post, :put, :patch, :delete, :head].each do |method|
        define_singleton_method(method) do |*args, **kwargs|
          inject_auth_headers_and_preserve_session(kwargs, test_instance)
          result = super(*args, **kwargs)
          store_session_cookie(test_instance)
          result
        end
      end

      define_singleton_method(:follow_redirect!) do |**kwargs|
        inject_auth_headers_and_preserve_session(kwargs, test_instance)
        result = super(**kwargs)
        store_session_cookie(test_instance)
        result
      end
    end

    mock_token
  end

  def jwt_token
    @jwt_token
  end

  def jwt_session_id
    @jwt_session_id
  end
end

RSpec.configure do |config|
  next unless AuthMethod.jwt?

  config.include JwtAuthenticationHelper, type: :request
  config.include JwtAuthenticationHelper, type: :controller
end
