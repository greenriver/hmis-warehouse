###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::ImportConfig, type: :model do
  describe '#host_name' do
    it 'returns the host when no port is specified' do
      config = build(:mhx_sftp_credentials, host: 'sftp.example.com')
      expect(config.host_name).to eq('sftp.example.com')
    end

    it 'strips the port when host includes a port' do
      config = build(:mhx_sftp_credentials, host: 'sftp.example.com:8022')
      expect(config.host_name).to eq('sftp.example.com')
    end
  end

  describe '#port_number' do
    it 'returns 22 when no port is specified' do
      config = build(:mhx_sftp_credentials, host: 'sftp.example.com')
      expect(config.port_number).to eq(22)
    end

    it 'returns the port when host includes a port' do
      config = build(:mhx_sftp_credentials, host: 'sftp.example.com:8022')
      expect(config.port_number).to eq(8022)
    end
  end
end
