require 'rails_helper'

RSpec.describe ClaimsReporting::Importer do
  let(:importer) { described_class.new }
  let(:test_credentials) do
    {
      'host' => 'sftp.example.com',
      'username' => 'testuser',
      'password' => 'testpass',
      'path' => '/uploads'
    }
  end

  describe '#default_credentials' do
    it 'returns the active claims_reporting import config' do
      config = build(:hmis_health_import_config, kind: :claims_reporting)
      allow(::Health::ImportConfig).to receive_message_chain(:active, :find_by).and_return(config)

      expect(importer.default_credentials).to eq(config)
    end
  end

  describe '#polling_enabled?' do
    it 'returns true when host and path are present' do
      allow(importer).to receive(:default_credentials).and_return(test_credentials)

      expect(importer.polling_enabled?).to be true
    end

    it 'returns false when host or path is missing' do
      credentials = test_credentials.merge('host' => nil)
      allow(importer).to receive(:default_credentials).and_return(credentials)

      expect(importer.polling_enabled?).to be false
    end
  end

  describe '#nightly!' do
    it 'calls import_all_from_health_sftp when polling is enabled' do
      allow(importer).to receive(:polling_enabled?).and_return(true)
      expect(importer).to receive(:import_all_from_health_sftp)

      importer.nightly!
    end

    it 'does nothing when polling is disabled' do
      allow(importer).to receive(:polling_enabled?).and_return(false)
      expect(importer).not_to receive(:import_all_from_health_sftp)

      importer.nightly!
    end
  end

  describe '#check_sftp' do
    let(:mock_sftp) { instance_double(Net::SFTP::Session) }
    let(:mock_dir) { instance_double(Net::SFTP::Operations::Dir) }
    let(:test_file_listing) do
      [
        double(name: 'claims_jan_2023.zip'),
        double(name: 'claims_feb_2023.zip'),
        double(name: 'other_document.pdf')
      ]
    end
    let(:root_path) { '/uploads' }

    before do
      allow(Net::SFTP).to receive(:start).and_yield(mock_sftp)
      allow(mock_sftp).to receive(:dir).and_return(mock_dir)
      allow(mock_dir).to receive(:glob).and_return(test_file_listing)
    end

    it 'returns files that match the naming convention' do
      results = importer.check_sftp(credentials: test_credentials, show_import_status: false, root_path: root_path)

      expect(results.size).to eq(2)
      expect(results.map { |r| r[:year] }).to all(eq('2023'))
    end
  end
end
