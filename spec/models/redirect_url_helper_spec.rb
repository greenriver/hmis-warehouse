###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RedirectUrlHelper do
  let(:session_id) { 'test-session-123' }
  let(:request) { double('Request', host: 'example.com', path: '/some/path', fullpath: '/some/path?foo=bar', xhr?: false, headers: {}) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:user) { double('User', my_root_path: '/user/dashboard') }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe '.redirect_url_after_auth' do
    context 'priority order' do
      it 'prefers rd parameter over cache' do
        RedirectManager.new(session_id).store('/cached/path')
        params[:rd] = '/rd/parameter/path'

        result = described_class.redirect_url_after_auth(
          params: params,
          request: request,
          session_id: session_id,
        )

        expect(result).to eq('/rd/parameter/path')
      end

      it 'falls back to cache when rd parameter is not present' do
        RedirectManager.new(session_id).store('/cached/path')

        result = described_class.redirect_url_after_auth(
          params: params,
          request: request,
          session_id: session_id,
        )

        expect(result).to eq('/cached/path')
      end

      it 'falls back to header when rd parameter and cache are not present' do
        request.headers['X-Auth-Request-Redirect'] = '/header/path'

        result = described_class.redirect_url_after_auth(
          params: params,
          request: request,
          session_id: session_id,
        )

        expect(result).to eq('/header/path')
      end

      it 'falls back to user.my_root_path when other sources are not present' do
        result = described_class.redirect_url_after_auth(
          params: params,
          request: request,
          session_id: session_id,
          user: user,
        )

        expect(result).to eq('/user/dashboard')
      end

      it 'returns nil when no sources are available' do
        result = described_class.redirect_url_after_auth(
          params: params,
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end
    end

    context 'URL validation' do
      it 'rejects unsafe URLs even if present in priority source' do
        params[:rd] = 'javascript:alert("xss")'

        result = described_class.redirect_url_after_auth(
          params: params,
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end

      it 'accepts safe relative URLs' do
        params[:rd] = '/admin/users'

        result = described_class.redirect_url_after_auth(
          params: params,
          request: request,
          session_id: session_id,
        )

        expect(result).to eq('/admin/users')
      end
    end
  end

  describe '.safe_redirect_url?' do
    let(:request) { double('Request', host: 'example.com') }

    context 'with relative paths' do
      it 'allows paths starting with /' do
        expect(described_class.safe_redirect_url?('/admin/users', request)).to be true
      end

      it 'allows paths with query parameters' do
        expect(described_class.safe_redirect_url?('/admin/users?page=2', request)).to be true
      end
    end

    context 'with absolute URLs' do
      it 'allows same-origin URLs' do
        expect(described_class.safe_redirect_url?('http://example.com/path', request)).to be true
      end

      it 'allows URLs without host' do
        expect(described_class.safe_redirect_url?('http:///path', request)).to be true
      end

      it 'rejects external URLs' do
        expect(described_class.safe_redirect_url?('http://evil.com/path', request)).to be false
      end
    end

    context 'with dangerous protocols' do
      it 'rejects javascript: URLs' do
        expect(described_class.safe_redirect_url?('javascript:alert("xss")', request)).to be false
      end

      it 'rejects data: URLs' do
        expect(described_class.safe_redirect_url?('data:text/html,<script>alert("xss")</script>', request)).to be false
      end

      it 'rejects vbscript: URLs' do
        expect(described_class.safe_redirect_url?('vbscript:msgbox("xss")', request)).to be false
      end

      it 'is case-insensitive for protocol checking' do
        expect(described_class.safe_redirect_url?('JavaScript:alert("xss")', request)).to be false
      end
    end

    context 'with invalid URLs' do
      it 'rejects blank URLs' do
        expect(described_class.safe_redirect_url?('', request)).to be false
      end

      it 'rejects nil URLs' do
        expect(described_class.safe_redirect_url?(nil, request)).to be false
      end

      it 'rejects malformed URLs' do
        expect(described_class.safe_redirect_url?('not a url', request)).to be false
      end
    end
  end

  describe '.capture_original_request_url' do
    let(:request) do
      double(
        'Request',
        xhr?: false,
        path: '/some/path',
        fullpath: '/some/path?foo=bar',
      )
    end

    context 'when request should be captured' do
      it 'returns the full path with query parameters' do
        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to eq('/some/path?foo=bar')
      end

      it 'stores URL in cache' do
        described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        stored_url = RedirectManager.new(session_id).get
        expect(stored_url).to eq('/some/path?foo=bar')
      end
    end

    context 'when request should not be captured' do
      it 'returns nil for AJAX requests' do
        allow(request).to receive(:xhr?).and_return(true)

        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end

      it 'returns nil for OAuth2-proxy endpoints' do
        allow(request).to receive(:path).and_return('/oauth2/sign_in')

        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end

      it 'returns nil for sign-in endpoints' do
        allow(request).to receive(:path).and_return('/users/sign_in')

        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end

      it 'returns nil for sign-out endpoints' do
        allow(request).to receive(:path).and_return('/users/sign_out')

        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end

      it 'returns nil for HMIS login endpoints' do
        allow(request).to receive(:path).and_return('/hmis/login')

        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end

      it 'returns nil for HMIS logout endpoints' do
        allow(request).to receive(:path).and_return('/hmis/logout')

        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end

      it 'returns nil when fullpath is blank' do
        allow(request).to receive(:fullpath).and_return('')

        result = described_class.capture_original_request_url(
          request: request,
          session_id: session_id,
        )

        expect(result).to be_nil
      end
    end

    context 'when session_id is blank' do
      it 'returns URL but does not store in cache' do
        result = described_class.capture_original_request_url(
          request: request,
          session_id: '',
        )

        expect(result).to eq('/some/path?foo=bar')
        expect(RedirectManager.new('').get).to be_nil
      end
    end
  end
end
