###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'strscan'

module Oauth2Proxy
  # Reads list settings from an oauth2-proxy TOML config file.
  class Config
    def self.load(path)
      new(File.read(path))
    end

    def initialize(text)
      @text = text
    end

    def skip_auth_routes
      @skip_auth_routes ||= patterns('skip_auth_routes')
    end

    def patterns(key)
      opening = @text.match(/^\s*#{Regexp.escape(key)}\s*=\s*\[/)
      raise KeyError, "#{key} is not set" unless opening

      scanner = StringScanner.new(opening.post_match)
      entries = []
      until scanner.eos?
        if scanner.scan(/"((?:[^"\\]|\\.)*)"/)
          entries << pattern(unescape(scanner[1]))
        elsif scanner.scan(/'([^'\n]*)'/)
          entries << pattern(scanner[1])
        elsif scanner.scan(/\]/)
          return entries
        elsif !scanner.skip(/\s+|,|#[^\n]*/)
          raise ArgumentError, "unexpected #{scanner.peek(20).inspect} in #{key}"
        end
      end
      raise ArgumentError, "#{key} has no closing ]"
    end

    # The spec matches entries against paths as plain regexes, so verb-scoped (METHOD=regex) and
    # unanchored entries would never match and would hide an over-broad skip.
    private def pattern(source)
      raise ArgumentError, "#{source} must start with ^/" unless source.start_with?('^/')

      Regexp.new(source)
    end

    private def unescape(string)
      string.gsub(/\\(.)/) do
        escaped = Regexp.last_match(1)
        raise ArgumentError, "unsupported escape \\#{escaped} in #{string}" unless escaped.in?(['\\', '"'])

        escaped
      end
    end
  end
end
