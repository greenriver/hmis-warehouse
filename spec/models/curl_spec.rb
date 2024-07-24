require 'rails_helper'

RSpec.describe Curl, type: :model do
  describe 'CA Certificate Works' do
    it 'does not throw an error when curling over https' do
      expect do
        Curl::Easy.perform('https://services.etosoftware.com/') do |http|
          # http.cacert = '/etc/ssl/certs/ca-certificates.crt'
          http.verbose = true
        end
      end.to_not raise_error
    end
  end
end
