# frozen_string_literal: true

require 'capybara'
require 'capybara/cuprite'
require 'uri'
require_relative 'e2e_debug_proxy'

# See documentation in: spec/support/E2E_README.md
# credit:
# https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing
# https://github.com/ParamagicDev/evil_systems

module E2eTests
  # Use a hostname that could be resolved in the internal Docker network
  # NOTE: Rails overrides Capybara.app_host in Rails <6.1, so we have
  # to store it differently
  CAPYBARA_APP_HOST = ENV.fetch('CAPYBARA_APP_HOST', "http://#{`hostname`.strip&.downcase || '0.0.0.0'}")

  raise 'CAPYBARA_APP_HOST must not have trailing slash' if CAPYBARA_APP_HOST =~ /\/\z/

  # rails 7 already has :cuprite
  DRIVER_NAME = :cuprite_remote

  module Setup
    class << self
      # The setup to be run prior to the test suite
      def perform(
        default_max_wait_time: 20,
        default_normalize_ws: true,
        automatic_label_click: true,
        enable_aria_label: true
      )
        # where the rails server runs
        ::Capybara.server_host = '0.0.0.0'
        ::Capybara.server_port = '4444' # override dynamic port

        # In Rails 6.1+ the following line should be enough
        ::Capybara.app_host = CAPYBARA_APP_HOST

        # Don't wait too long in `have_xyz` matchers
        ::Capybara.default_max_wait_time = default_max_wait_time

        ::Capybara.enable_aria_label = enable_aria_label

        ::Capybara.automatic_label_click = automatic_label_click

        ::Capybara.ignore_hidden_elements = true

        # Normalizes whitespaces when using `has_text?` and similar matchers
        ::Capybara.default_normalize_ws = default_normalize_ws

        # Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
        # It could be useful to be able to configure this path from the outside (e.g., on CI).
        ::Capybara.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')

        verify_chromium_installation!

        remote_port, _proxy_port = debugging_ports
        driver_options = cuprite_options(remote_port)

        ::Capybara.register_driver(DRIVER_NAME) do |app|
          ::Capybara::Cuprite::Driver.new(app, **driver_options)
        end
      end

      def debugging_ports
        remote_port = debugging_remote_port
        proxy_port = debugging_proxy_port(remote_port)
        ensure_proxy_port_env(proxy_port, remote_port)
        [remote_port, proxy_port]
      end

      private

      def verify_chromium_installation!
        chromium_path = ENV.fetch('CHROMIUM_PATH', '/usr/bin/chromium')
        return if File.executable?(chromium_path)

        raise "Chromium not found at #{chromium_path}. Please install Chromium or set CHROMIUM_PATH."
      end

      def cuprite_options(remote_port)
        {
          extensions: ["#{Rails.root}/spec/assets/disable_transitions.js"], # https://github.com/rubycdp/ferrum?tab=readme-ov-file#customization
          window_size: [1200, 1600],
          browser_options: browser_options(remote_port),
          headless: true,
          js_errors: true,
          logger: FerrumLogger.new,
          inspector: ENV.key?('CHROME_DEBUGGING_PORT'),
          browser_path: ENV.fetch('CHROMIUM_PATH', '/usr/bin/chromium'),
        }
      end

      def browser_options(remote_port)
        options = { 'no-sandbox' => nil, 'disable-dev-shm-usage' => nil }
        options['remote-debugging-port'] = remote_port if remote_port
        options
      end

      def debugging_remote_port
        value = ENV['CHROME_DEBUGGING_PORT']
        return nil if value.blank?

        Integer(value, 10)
      rescue ArgumentError
        Kernel.warn("Invalid CHROME_DEBUGGING_PORT: #{value.inspect}")
        nil
      end

      def debugging_proxy_port(remote_port)
        return nil unless remote_port

        value = ENV['CHROME_DEBUGGING_PROXY_PORT']
        return remote_port - 1 if value.blank?

        Integer(value, 10)
      rescue ArgumentError
        Kernel.warn("Invalid CHROME_DEBUGGING_PROXY_PORT: #{value.inspect}")
        remote_port - 1
      end

      def ensure_proxy_port_env(proxy_port, remote_port)
        return if proxy_port.nil? || proxy_port == remote_port || proxy_port < 1

        ENV['CHROME_DEBUGGING_PROXY_PORT'] = proxy_port.to_s if ENV['CHROME_DEBUGGING_PROXY_PORT'].blank?
      end
    end
  end

  module CupriteHelpers
    # Pauses the current driver
    # @return [nil]
    def pause
      $stdout.puts '🔎 Pausing browser for inspection'
      page.driver.pause
    end

    # Opens a debug session via Pry if defined, else uses Irb.
    def debug(binding = nil)
      if ENV['CHROME_DEBUGGING_PORT']
        remote_port, proxy_port = Setup.debugging_ports
        DebugProxy.start(remote_port: remote_port, proxy_port: proxy_port)

        $stdout.puts "🔎 Open Chrome inspector at http://#{chrome_debugging_host}:#{chrome_debugging_port}"
        $stdout.puts "   (Cuprite WS endpoint: #{cuprite_ws_endpoint})" if cuprite_ws_endpoint.present?
      else
        $stdout.puts '🔎 Pausing browser for inspection'
      end

      if binding
        return binding.pry if defined?(Pry)

        return binding.irb
      end

      page.driver.pause
    end

    private

    def chrome_debugging_host
      return ENV['CHROME_DEBUGGING_HOST'].presence if ENV['CHROME_DEBUGGING_HOST'].present?

      docker_host = ENV['DOCKER_HOST']
      return 'localhost' if docker_host.blank?

      uri = URI.parse(docker_host)
      return uri.host if uri.respond_to?(:host) && uri.host.present?

      docker_host.match?(/\A[\w.\-]+\z/) ? docker_host : 'localhost'
    rescue URI::InvalidURIError
      'localhost'
    end

    def chrome_debugging_port
      ENV['CHROME_DEBUGGING_PROXY_PORT'].presence || ENV['CHROME_DEBUGGING_PORT']
    end

    def cuprite_ws_endpoint
      page.driver&.browser&.process&.ws_url
    rescue NoMethodError
      nil
    end
  end

  module Helpers
    include ActionView::RecordIdentifier if defined? ::Rails
    include CupriteHelpers if defined? ::Capybara::Cuprite

    # Use our `Capybara.save_path` to store screenshots with other capybara artifacts
    # @return [String]
    def absolute_image_path
      return ::Rails.root.join("#{::Capybara.save_path}/screenshots/#{image_name}.png") if defined? ::Rails

      File.join("#{::Capybara.save_path}/screenshots/#{image_name}.png")
    end

    # Use relative path in screenshot message to make it clickable in VS Code when running in Docker
    # @return [String]
    def image_path
      return absolute_image_path.relative_path_from(::Rails.root).to_s if defined? ::Rails

      absolute_image_path.relative_path_from(Dir.pwd)
    end
  end

  # https://github.com/rubycdp/cuprite/issues/113#issuecomment-801133067
  class FerrumLogger
    attr_reader :logs

    def initialize
      @logs = []
    end

    def truncate
      @logs = []
    end

    def puts(log_str)
      return if log_str.nil?

      _log_symbol, _log_time, log_body_str = log_str.strip.split(' ', 3)

      return if log_body_str.nil?

      log_body = begin
        JSON.parse(log_body_str)
       rescue JSON::ParserError
         nil
      end
      return if log_body.nil?

      case log_body['method']
      when 'Runtime.consoleAPICalled'
        # ignore console cruft

      when 'Runtime.exceptionThrown'
        # noop, this is already logged because we have "js_errors: true" in cuprite.

      when 'Log.entryAdded'
        # capture error message
        msg = "#{log_body['params']['entry']['url']} - #{log_body['params']['entry']['text']}"
        # Kernel.puts msg
        @logs.push msg
      end
    end
  end
end
