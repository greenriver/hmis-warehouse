###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::PostAuthRedirect do
  # Minimal stand-in for the controller cookie jar. We only exercise the contract the
  # service relies on: an `encrypted` sub-jar with []/[]= (assignment takes a hash with a
  # :value, reads return that value) and a top-level `delete`. Real encryption/signing is
  # Rails' concern and covered by request specs, not this unit.
  let(:cookie_jar_class) do
    Class.new do
      def initialize
        @store = {}
      end

      def encrypted
        @encrypted ||= Encrypted.new(@store)
      end

      def delete(key, *)
        @store.delete(key)
      end

      class Encrypted
        def initialize(store)
          @store = store
        end

        def [](key)
          @store[key]
        end

        def []=(key, options)
          @store[key] = options.is_a?(Hash) ? options[:value] : options
        end
      end
    end
  end
  let(:cookies) { cookie_jar_class.new }
  let(:cookie_key) { Idp::PostAuthRedirect::REDIRECT_COOKIE }

  let(:params) { ActionController::Parameters.new({}) }
  let(:user) { double('User', my_root_path: '/user/dashboard') }
  let(:request) { double('Request', host: 'example.com', path: '/some/path', fullpath: '/some/path?foo=bar', xhr?: false, headers: {}) }

  subject(:service) { described_class.new(request: request, cookies: cookies) }

  describe '#resolve' do
    context 'priority order' do
      it 'prefers rd parameter over the cookie' do
        cookies.encrypted[cookie_key] = '/cookie/path'
        params[:rd] = '/rd/parameter/path'

        expect(service.resolve(params: params)).to eq('/rd/parameter/path')
      end

      it 'falls back to the cookie when rd parameter is not present' do
        cookies.encrypted[cookie_key] = '/cookie/path'

        expect(service.resolve(params: params)).to eq('/cookie/path')
      end

      it 'falls back to header when rd parameter and cookie are not present' do
        request.headers['X-Auth-Request-Redirect'] = '/header/path'

        expect(service.resolve(params: params)).to eq('/header/path')
      end

      it 'clears the backup cookie once consumed' do
        cookies.encrypted[cookie_key] = '/cookie/path'

        service.resolve(params: params)

        expect(cookies.encrypted[cookie_key]).to be_nil
      end

      it 'clears a stale backup cookie even when the rd parameter wins' do
        cookies.encrypted[cookie_key] = '/cookie/path'
        params[:rd] = '/rd/parameter/path'

        service.resolve(params: params)

        expect(cookies.encrypted[cookie_key]).to be_nil
      end

      it 'falls back to user.my_root_path when other sources are not present' do
        expect(service.resolve(params: params, user: user)).to eq('/user/dashboard')
      end

      it 'returns nil when no sources are available' do
        expect(service.resolve(params: params)).to be_nil
      end
    end

    context 'URL validation' do
      it 'rejects unsafe URLs even if present in priority source' do
        params[:rd] = 'javascript:alert("xss")'

        expect(service.resolve(params: params)).to be_nil
      end

      it 'accepts safe relative URLs' do
        params[:rd] = '/admin/users'

        expect(service.resolve(params: params)).to eq('/admin/users')
      end
    end
  end

  describe '.safe?' do
    let(:request) { double('Request', host: 'example.com') }

    context 'with relative paths' do
      it 'allows paths starting with /' do
        expect(described_class.safe?('/admin/users', request)).to be true
      end

      it 'allows paths with query parameters' do
        expect(described_class.safe?('/admin/users?page=2', request)).to be true
      end
    end

    context 'with absolute URLs' do
      it 'allows same-origin URLs' do
        expect(described_class.safe?('http://example.com/path', request)).to be true
      end

      it 'allows URLs without host' do
        expect(described_class.safe?('http:///path', request)).to be true
      end

      it 'rejects external URLs' do
        expect(described_class.safe?('http://evil.com/path', request)).to be false
      end
    end

    context 'with protocol-relative / backslash-obfuscated URLs' do
      it 'rejects protocol-relative URLs' do
        expect(described_class.safe?('//evil.com/path', request)).to be false
      end

      it 'rejects forward-then-backslash URLs' do
        expect(described_class.safe?('/\\evil.com/path', request)).to be false
      end

      it 'rejects leading-backslash URLs' do
        expect(described_class.safe?('\\\\evil.com/path', request)).to be false
      end
    end

    context 'with dangerous protocols' do
      it 'rejects javascript: URLs' do
        expect(described_class.safe?('javascript:alert("xss")', request)).to be false
      end

      it 'rejects data: URLs' do
        expect(described_class.safe?('data:text/html,<script>alert("xss")</script>', request)).to be false
      end

      it 'rejects vbscript: URLs' do
        expect(described_class.safe?('vbscript:msgbox("xss")', request)).to be false
      end

      it 'is case-insensitive for protocol checking' do
        expect(described_class.safe?('JavaScript:alert("xss")', request)).to be false
      end
    end

    context 'with invalid URLs' do
      it 'rejects blank URLs' do
        expect(described_class.safe?('', request)).to be false
      end

      it 'rejects nil URLs' do
        expect(described_class.safe?(nil, request)).to be false
      end

      it 'rejects malformed URLs' do
        expect(described_class.safe?('not a url', request)).to be false
      end
    end
  end

  describe '#capture' do
    let(:request) do
      double(
        'Request',
        get?: true,
        xhr?: false,
        format: Mime[:html],
        path: '/some/path',
        fullpath: '/some/path?foo=bar',
      )
    end

    context 'when request should be captured' do
      it 'returns the full path with query parameters' do
        expect(service.capture).to eq('/some/path?foo=bar')
      end

      it 'stores the URL in the backup cookie' do
        service.capture

        expect(cookies.encrypted[cookie_key]).to eq('/some/path?foo=bar')
      end

      it 'does not store an over-length URL in the cookie' do
        long_url = "/some/path?foo=#{'a' * Idp::PostAuthRedirect::MAX_REDIRECT_URL_LENGTH}"
        allow(request).to receive(:fullpath).and_return(long_url)

        expect(service.capture).to eq(long_url)
        expect(cookies.encrypted[cookie_key]).to be_nil
      end
    end

    context 'when request should not be captured' do
      it 'returns nil for AJAX requests' do
        allow(request).to receive(:xhr?).and_return(true)

        expect(service.capture).to be_nil
      end

      it 'returns nil for non-GET requests' do
        allow(request).to receive(:get?).and_return(false)

        expect(service.capture).to be_nil
      end

      it 'returns nil for non-HTML (JSON/API) requests' do
        allow(request).to receive(:format).and_return(Mime[:json])

        expect(service.capture).to be_nil
      end

      it 'returns nil for OAuth2-proxy endpoints (path prefix)' do
        allow(request).to receive(:path).and_return('/oauth2/sign_in')

        expect(service.capture).to be_nil
      end

      # One representative of the excluded-path list (sign-in/out, hmis login/logout);
      # they all exercise the same request.path.in?([...]) membership check.
      it 'returns nil for excluded auth endpoints' do
        allow(request).to receive(:path).and_return('/users/sign_in')

        expect(service.capture).to be_nil
      end

      it 'returns nil when fullpath is blank' do
        allow(request).to receive(:fullpath).and_return('')

        expect(service.capture).to be_nil
      end
    end
  end
end
