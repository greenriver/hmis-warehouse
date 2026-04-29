# frozen_string_literal: true

require 'rails_helper'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'tmpdir'

# Census API, TalentLMS and Superset use curl
RSpec.describe Curl, type: :model do
  describe 'CA Certificate Works' do
    # Spin up a local HTTPS server with a self-signed cert so we can test
    # that curb establishes TLS when given an explicit CA cert file
    before(:all) do
      @tmpdir = Dir.mktmpdir

      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = OpenSSL::X509::Name.parse('/CN=localhost')
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.now
      cert.not_after = Time.now + 3600
      cert.sign(key, OpenSSL::Digest.new('SHA256'))

      @cacert_path = File.join(@tmpdir, 'ca.crt')
      File.write(@cacert_path, cert.to_pem)

      @server = WEBrick::HTTPServer.new(
        Port: 0,
        SSLEnable: true,
        SSLCertificate: cert,
        SSLPrivateKey: key,
        Logger: WEBrick::Log.new(File::NULL, WEBrick::Log::FATAL),
        AccessLog: [],
      )
      @server.mount_proc('/') { |_req, res| res.body = 'OK' }
      @server_thread = Thread.new { @server.start }
      @port = @server.config[:Port]
    end

    after(:all) do
      @server&.shutdown
      @server_thread&.join
      FileUtils.remove_entry(@tmpdir)
    end

    before do
      WebMock.allow_net_connect!
    end

    after do
      WebMock.disable_net_connect!
    end

    it 'does not throw an error when curling over https with an explicit CA cert file' do
      expect do
        Curl::Easy.perform("https://localhost:#{@port}/") do |http|
          http.cacert = @cacert_path
          http.verbose = true
        end
      end.not_to raise_error
    end
  end
end
