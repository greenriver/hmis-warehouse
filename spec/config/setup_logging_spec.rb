# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetupLogging do
  describe 'lograge custom options' do
    let(:lograge_config) do
      Class.new do
        attr_accessor :logger, :formatter, :base_controller_class, :custom_options
      end.new
    end

    let(:config) do
      Class.new do
        attr_reader :lograge

        def initialize(lograge)
          @lograge = lograge
        end
      end.new(lograge_config)
    end

    let(:setup_logging) { described_class.new(config) }

    let(:custom_options) do
      setup_logging.send(:_configure_lograge)
      lograge_config.custom_options
    end

    let(:headers_env) { {} }

    let(:headers) do
      Class.new do
        attr_reader :env

        def initialize(env)
          @env = env
        end
      end.new(headers_env)
    end

    let(:request) do
      double(
        remote_ip: request_remote_ip,
        headers: headers,
        protocol: 'https://',
        host: 'example.org',
      )
    end

    let(:request_remote_ip) { '10.0.0.1' }

    let(:event_payload) do
      {
        request: request,
        remote_ip: event_remote_ip,
        x_forwarded_for: event_x_forwarded_for,
        remote_addr: event_remote_addr,
        headers: { 'action_dispatch.request_id' => 'req-123' },
      }
    end

    let(:event_remote_ip) { nil }
    let(:event_remote_addr) { nil }
    let(:event_x_forwarded_for) { nil }

    let(:event) { double(payload: event_payload) }

    context 'when request has a remote_ip' do
      it 'logs the request remote_ip' do
        result = custom_options.call(event)

        expect(result[:remote_ip]).to eq('10.0.0.1')
        expect(result[:ip]).to eq('10.0.0.1')
      end
    end

    context 'when request remote_ip is blank but X-Forwarded-For is present' do
      let(:request_remote_ip) { nil }
      let(:headers_env) { { 'HTTP_X_FORWARDED_FOR' => '11.22.33.44, 55.66.77.88' } }

      it 'logs the first X-Forwarded-For value' do
        result = custom_options.call(event)

        expect(result[:remote_ip]).to eq('11.22.33.44')
        expect(result[:ip]).to eq('11.22.33.44')
        expect(result[:x_forwarded_for]).to eq('11.22.33.44, 55.66.77.88')
      end
    end

    context 'when only remote_addr is available' do
      let(:request_remote_ip) { nil }
      let(:headers_env) { { 'REMOTE_ADDR' => '203.0.113.5' } }

      it 'falls back to remote_addr for remote_ip' do
        result = custom_options.call(event)

        expect(result[:remote_ip]).to eq('203.0.113.5')
        expect(result[:ip]).to be_nil
      end
    end
  end
end
