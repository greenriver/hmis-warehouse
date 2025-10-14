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

        def [](key)
          @env[key]
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
        host: 'example.org',
        server_protocol: 'https://',
        headers: { 'action_dispatch.request_id' => 'req-123' },
        remote_ip: 'event-remote-ip',
        ip: 'event-client-ip',
        x_forwarded_for: 'event-xff',
        remote_addr: 'event-remote-addr',
        session_id: 'session-123',
        user_id: 42,
        pid: 1234,
        request_start: 't=1234',
      }
    end

    let(:event) { double(payload: event_payload) }

    it 'merges payload IP data with other logging attributes' do
      result = custom_options.call(event)

      expect(result).to include(remote_ip: 'event-remote-ip')
      expect(result).to include(ip: 'event-client-ip')
      expect(result).to include(remote_addr: 'event-remote-addr')
      expect(result).to include(x_forwarded_for: 'event-xff')
      expect(result[:host]).to eq('example.org')
      expect(result[:server_protocol]).to eq('https://')
      expect(result[:request_id]).to eq('req-123')
      expect(result[:session_id]).to eq('session-123')
      expect(result[:user_id]).to eq(42)
      expect(result[:pid]).to eq(1234)
      expect(result[:x_amzn_trace_id]).to be_nil
    end

    context 'when payload values are blank' do
      let(:event_payload) do
        {
          request: request,
          host: 'example.org',
          server_protocol: 'https://',
          headers: { 'action_dispatch.request_id' => 'req-123' },
          remote_ip: nil,
          ip: '',
          x_forwarded_for: nil,
          remote_addr: '',
          session_id: nil,
          user_id: nil,
          pid: nil,
          request_start: nil,
        }
      end

      it 'drops blank values from the payload' do
        result = custom_options.call(event)

        expect(result).not_to have_key(:remote_ip)
        expect(result).not_to have_key(:ip)
        expect(result).not_to have_key(:remote_addr)
        expect(result).not_to have_key(:x_forwarded_for)
        expect(result).not_to have_key(:session_id)
        expect(result).not_to have_key(:user_id)
        expect(result).not_to have_key(:pid)
        expect(result).not_to have_key(:request_start)
      end
    end

    context 'when event payload is missing' do
      it 'raises an error' do
        expect { custom_options.call(double(payload: nil)) }.to raise_error('Lograge event payload missing')
      end
    end
  end
end
