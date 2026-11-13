###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SentryEventFilter do
  subject(:filter) { described_class.new(['password', 'token', 'api_key', 'secret']) }

  def build_event(tags: {}, extra: {}, contexts: {}, user: {})
    event = Sentry::ErrorEvent.new(configuration: Sentry::Configuration.new)
    event.tags = tags
    event.extra = extra
    event.contexts = contexts
    event.user = user
    event
  end

  describe '#call' do
    it 'redacts sensitive values (including nested) across tags, extra, contexts, and user while preserving safe ones' do
      event = build_event(
        tags: { environment: 'production', password: 'tag-secret' },
        extra: { request_id: 'abc-123', token: 'extra-secret' },
        contexts: { runtime: { name: 'ruby', password: 'nested-secret' }, api_key: 'context-secret' },
        user: { id: 42, secret: 'user-secret' },
      )

      result = filter.call(event, {})

      expect(result.tags).to eq(environment: 'production', password: '[FILTERED]')
      expect(result.extra).to eq(request_id: 'abc-123', token: '[FILTERED]')
      expect(result.contexts).to eq(
        runtime: { name: 'ruby', password: '[FILTERED]' },
        api_key: '[FILTERED]',
      )
      expect(result.user).to eq(id: 42, secret: '[FILTERED]')
    end

    it 'returns the same Sentry::ErrorEvent object rather than a Hash or copy' do
      event = build_event
      result = filter.call(event, {})

      expect(result).to equal(event)
      expect(result).to be_a(Sentry::ErrorEvent)
    end

    it 'redacts sensitive request headers while preserving safe ones' do
      event = build_event
      event.rack_env = {
        'REQUEST_METHOD' => 'POST',
        'PATH_INFO' => '/x',
        'HTTP_X_PASSWORD' => 'header-secret',
        'HTTP_X_TRACE_ID' => 'trace-1',
      }

      result = filter.call(event, {})

      expect(result.request.headers['X-Password']).to eq('[FILTERED]')
      expect(result.request.headers['X-Trace-Id']).to eq('trace-1')
    end

    it 'redacts sensitive keys inside request.data when it is a Hash' do
      event = build_event
      event.rack_env = { 'REQUEST_METHOD' => 'POST', 'PATH_INFO' => '/x' }
      event.request.data = { 'safe_param' => 'ok', 'password' => 'form-secret' }

      result = filter.call(event, {})

      expect(result.request.data).to eq('safe_param' => 'ok', 'password' => '[FILTERED]')
    end

    it 'leaves request.data untouched (rather than raising) when it is a raw string body' do
      event = build_event
      event.rack_env = { 'REQUEST_METHOD' => 'POST', 'PATH_INFO' => '/x' }
      event.request.data = '{"password":"raw-json-body"}'

      result = filter.call(event, {})

      expect(result.request.data).to eq('{"password":"raw-json-body"}')
    end

    it 'does not raise and leaves request nil for events with no associated request (e.g. background jobs)' do
      event = build_event(extra: { token: 'extra-secret' })
      expect(event.request).to be_nil

      result = filter.call(event, {})

      expect(result.request).to be_nil
      expect(result.extra).to eq(token: '[FILTERED]')
    end
  end
end
