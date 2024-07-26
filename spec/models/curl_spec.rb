require 'rails_helper'
require 'vcr'

RSpec.describe Curl, type: :model do
  describe 'CA Certificate Works' do
    before do
      WebMock.allow_net_connect!
    end

    after do
      WebMock.disable_net_connect!
    end

    # NOTE: this test may fail locally, it only appears to be broken when deployed and in CI
    it 'does throw an error when curling over https' do
      VCR.turned_off do
        expect do
          Curl::Easy.perform('https://services.etosoftware.com/') do |http|
            # Without defining a CA Cert we throw an error
            # http.cacert = '/etc/ssl/certs/ca-certificates.crt'
            http.verbose = true
          end
        end.to raise_error(Curl::Err::SSLCaertBadFile)
      end
    end

    it 'does not throw an error when curling over https with an explicit CA Cert file' do
      VCR.turned_off do
        expect do
          Curl::Easy.perform('https://services.etosoftware.com/') do |http|
            http.cacert = '/etc/ssl/certs/ca-certificates.crt'
            http.verbose = true
          end
        end.to_not raise_error
      end
    end
  end
end
