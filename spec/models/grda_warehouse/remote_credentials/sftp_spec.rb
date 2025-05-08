# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::RemoteCredentials::Sftp do
  describe 'attribute assignment' do
    it 'assigns aliased attributes correctly' do
      sftp = described_class.new(
        host: 'sftp.example.com',
        private_key: 'key123',
        port: '22',
      )
      expect(sftp.host).to eq('sftp.example.com')
      expect(sftp.private_key).to eq('key123')
      expect(sftp.port).to eq('22')
    end
  end
end
