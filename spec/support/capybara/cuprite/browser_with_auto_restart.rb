# frozen_string_literal: true

require 'capybara/cuprite'

module Capybara
  module Cuprite
    module BrowserWithAutoRestart
      EXCEPTIONS_TO_CATCH = [
        Ferrum::DeadBrowserError,
        Ferrum::NoSuchTargetError,
        Ferrum::TimeoutError,
      ].freeze

      def visit(...)
        tries = 0
        max_tries = 3

        begin
          super
        rescue *EXCEPTIONS_TO_CATCH => e
          tries += 1
          raise unless tries < max_tries

          Rails.logger.warn("Browser crashed with error: #{e.class} (#{Time.current})")
          Rails.logger.warn('Restarting browser...')

          Capybara.current_session.driver.browser.restart
          Capybara.reset!

          Rails.logger.warn("Browser restarted (#{Time.current})")
          retry
        end
      end
    end
  end
end

Capybara::Cuprite::Browser.prepend(Capybara::Cuprite::BrowserWithAutoRestart)
