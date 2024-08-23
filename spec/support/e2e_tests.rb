# frozen_string_literal: true

require 'capybara'
require 'capybara/cuprite'

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
    # The setup to be run prior to the test suite
    def self.perform(
      process_timeout: 30,
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

      # Normalizes whitespaces when using `has_text?` and similar matchers
      ::Capybara.default_normalize_ws = default_normalize_ws

      # Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
      # It could be useful to be able to configure this path from the outside (e.g., on CI).
      ::Capybara.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')

      raise "can't connect to chrome on #{ENV['CHROME_URL']} run `docker-compose up -d chrome`" unless RemoteChrome.connected?

      remote_options = RemoteChrome.options
      ::Capybara.register_driver(DRIVER_NAME) do |app|
        ::Capybara::Cuprite::Driver.new(
          app,
          **{
            window_size: [1200, 1600],
            # flatten: false, # https://github.com/rubycdp/ferrum/issues/470
            browser_options: RemoteChrome.connected? ? { 'no-sandbox' => nil } : {},
            headless: ENV.fetch('CI', 'true') == 'true',
            process_timeout: process_timeout,
            js_errors: true,
            logger: FerrumLogger.new,
            inspector: true,
          }.merge(remote_options),
        )
      end
    end
  end

  module RemoteChrome
    # @return [String, nil]
    def self.url
      ENV['CHROME_URL']
    end

    # Current port
    # @return Integer
    def self.port
      URI.parse(url).yield_self(&:port)
    end

    # Current host
    # @return [String, nil]
    def self.host
      URI.parse(url).yield_self(&:host) if url
    end

    # Returns a hash with a :url key / value if a remote chrome url is found.
    # @return [Hash{:url => String, nil}]
    #
    def self.options
      # Check whether the remote chrome is running and configure the Capybara
      # driver for it.
      connected? ? { url: url } : {}
    end

    # Whether or not the socket could be connected
    # @return [Boolean]
    def self.connected?
      if url.nil?
        false
      else
        Socket.tcp(host, port, connect_timeout: 5).close
        true
      end
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
      false
    end
  end

  module CupriteHelpers
    # Pauses the current driver
    # @return [nil]
    def pause
      page.driver.pause
    end

    # Opens a debug session via Pry if defined, else uses Irb.
    def debug(binding = nil)
      $stdout.puts '🔎 Open Chrome inspector at http://localhost:3333'
      if binding
        return binding.pry if defined?(Pry)

        return binding.irb
      end

      page.driver.pause
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
      _log_symbol, _log_time, log_body_str = log_str.strip.split(' ', 3)

      return if log_body_str.nil?

      log_body = JSON.parse(log_body_str)

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
