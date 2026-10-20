###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Oauth2Proxy::Config do
  let(:config) do
    described_class.new(<<~'CFG')
      cookie_name="_oauth2_proxy"
      skip_auth_routes=[
        "^/$",  # root [anchored]
        # "^/commented_out",
        "^/hmis/user\\.json$",
        "^/document_exports/[0-9]+$"
      ]
      api_routes=[
        "^/api/",
      ]
    CFG
  end

  describe '#patterns' do
    it 'returns the active entries of the named list as regexes, unescaping TOML strings' do
      expect(config.patterns('skip_auth_routes').map(&:source)).to eq(
        [
          '^/$',
          '^/hmis/user\.json$',
          '^/document_exports/[0-9]+$',
        ],
      )
    end

    it 'reads a list other than skip_auth_routes' do
      expect(config.patterns('api_routes').map(&:source)).to eq(['^/api/'])
    end

    it 'raises KeyError when the list is not set' do
      expect { config.patterns('whitelist_domains') }.to raise_error(KeyError, /whitelist_domains/)
    end

    it 'raises ArgumentError on an escape other than \\\\ or \\"' do
      bad = described_class.new(%(skip_auth_routes=[\n  "^/a\\d"\n]\n))

      expect { bad.patterns('skip_auth_routes') }.to raise_error(ArgumentError, /unsupported escape/)
    end

    it 'reads TOML literal strings verbatim, including a ] inside them' do
      literal = described_class.new(<<~'CFG')
        skip_auth_routes=[
          '^/document_exports/[0-9]+$',
          "^/after"
        ]
      CFG

      expect(literal.patterns('skip_auth_routes').map(&:source)).to eq(['^/document_exports/[0-9]+$', '^/after'])
    end

    it 'raises ArgumentError on an unquoted entry' do
      bare = described_class.new("skip_auth_routes=[\n  ^/bare\n]\n")

      expect { bare.patterns('skip_auth_routes') }.to raise_error(ArgumentError, /unexpected/)
    end

    it 'raises ArgumentError on an entry that does not start with ^/, such as a verb-scoped one' do
      verb_scoped = described_class.new(%(skip_auth_routes=[\n  "GET=^/foo"\n]\n))

      expect { verb_scoped.patterns('skip_auth_routes') }.to raise_error(ArgumentError, /must start with \^\//)
    end
  end

  describe '.load' do
    it 'reads skip_auth_routes from the warehouse dev config' do
      config = described_class.load(Rails.root.join('docker/auth/dev.oauth2-proxy-warehouse.cfg'))

      expect(config.skip_auth_routes.map(&:source)).to include('^/public_agencies', '^/hmis/user\.json$')
    end
  end
end
