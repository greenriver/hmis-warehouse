###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# CI provides an SFTP service for the test job (see hmis-warehouse-sftp in
# .github/workflows/rails_tests.yml). These examples stub Open3. Live SFTP
# integration examples are in this file's "SFTP integration" describe block;
# locally: docker compose up -d sftp (SFTP_HOST=sftp in .env.test).

require 'rails_helper'

RSpec.describe Health::ImportConfig, type: :model do
  let(:connection) { instance_double(Sftp::Cli) }

  before do
    allow(Sftp::Cli).to receive(:start).and_yield(connection)
    allow(connection).to receive(:download!)
    allow(connection).to receive(:upload!)
    allow(connection).to receive(:mkdir_p!)
    allow(connection).to receive(:dir).and_return(instance_double(Sftp::Cli::DirProxy, foreach: []))
  end

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

  describe '#get' do
    let(:config) { build(:mhx_sftp_credentials) }

    it 'downloads the remote path to a local file' do
      config.get('/sftp/export.csv', '/tmp/export.csv')

      expect(connection).to have_received(:download!).with('/sftp/export.csv', '/tmp/export.csv', recursive: false)
    end

    it 'downloads recursively when requested' do
      config.get('/sftp/exports', '/tmp/exports', recursive: true)

      expect(connection).to have_received(:download!).with('/sftp/exports', '/tmp/exports', recursive: true)
    end
  end

  describe '#put' do
    let(:config) { build(:mhx_sftp_credentials) }

    it 'uploads the local file to the remote path' do
      config.put('/tmp/export.csv', '/sftp/export.csv')

      expect(connection).to have_received(:upload!).with('/tmp/export.csv', '/sftp/export.csv')
    end
  end

  describe '#put_with_mkdir_p' do
    let(:config) { build(:mhx_sftp_credentials) }

    it 'creates parent directories then uploads the file' do
      config.put_with_mkdir_p('/local/17-careplan.pdf', '/sftp/carehub_export/2026-06-23/health_careplans/17-careplan.pdf')

      expect(connection).to have_received(:mkdir_p!).with('/sftp/carehub_export/2026-06-23/health_careplans')
      expect(connection).to have_received(:upload!).with(
        '/local/17-careplan.pdf',
        '/sftp/carehub_export/2026-06-23/health_careplans/17-careplan.pdf',
      )
    end
  end

  describe '#ls' do
    let(:config) { build(:mhx_sftp_credentials) }
    let(:entry) { Sftp::Cli::RemoteFile.new(name: 'export.csv', longname: '-rw-r--r-- export.csv') }

    before do
      dir_proxy = instance_double(Sftp::Cli::DirProxy)
      allow(connection).to receive(:dir).and_return(dir_proxy)
      allow(dir_proxy).to receive(:foreach).and_yield(entry)
    end

    it 'lists directory entries' do
      expect { config.ls('/sftp') }.to output(include('export.csv')).to_stdout
    end
  end
end

RSpec.describe Health::ImportConfig, 'SFTP integration', :sftp_integration, type: :model do
  let(:config) { sftp_integration_import_config }
  let(:remote_dir) { sftp_integration_remote_dir }
  let(:created_remote_paths) { [] }

  before do
    config.connect { |connection| connection.mkdir_p!(remote_dir) }
  end

  after do
    sftp_integration_remove_remote_paths(created_remote_paths)
  end

  describe '#put (Sftp::Cli#upload!)' do
    it 'uploads a file under the configured SFTP path' do
      remote = File.join(remote_dir, 'upload.txt')
      created_remote_paths << remote

      Tempfile.create('sftp-upload') do |local|
        local.write('upload integration content')
        local.flush
        local.close
        config.put(local.path, remote)
      end

      Tempfile.create('sftp-upload-check') do |downloaded|
        config.get(remote, downloaded.path)
        downloaded.flush
        expect(downloaded.read).to eq('upload integration content')
      end
    end
  end

  describe 'Sftp::Cli#mkdir_p!' do
    it 'creates nested directories under the writable path' do
      nested_dir = File.join(remote_dir, 'nested', 'deep')
      config.connect { |connection| connection.mkdir_p!(nested_dir) }

      remote = File.join(nested_dir, 'probe.txt')
      created_remote_paths << remote

      Tempfile.create('sftp-mkdir-probe') do |local|
        local.write('mkdir probe')
        local.flush
        local.close
        config.put(local.path, remote)
      end

      Tempfile.create('sftp-mkdir-check') do |downloaded|
        config.get(remote, downloaded.path)
        downloaded.flush
        expect(downloaded.read).to eq('mkdir probe')
      end
    end
  end

  describe '#get (Sftp::Cli#download!)' do
    it 'downloads a file that was uploaded to the server' do
      remote = File.join(remote_dir, 'download.txt')
      created_remote_paths << remote

      Tempfile.create('sftp-download-source') do |local|
        local.write('download integration content')
        local.flush
        local.close
        config.put_with_mkdir_p(local.path, remote)
      end

      Tempfile.create('sftp-download-target') do |downloaded|
        config.get(remote, downloaded.path)
        downloaded.flush
        expect(downloaded.read).to eq('download integration content')
      end
    end
  end

  describe 'Sftp::Cli#dir.glob' do
    it 'lists remote files matching a glob pattern' do
      csv_remote = File.join(remote_dir, 'export.csv')
      txt_remote = File.join(remote_dir, 'notes.txt')
      created_remote_paths << csv_remote << txt_remote

      Tempfile.create('sftp-glob-csv') do |csv_local|
        csv_local.write('csv')
        csv_local.flush
        csv_local.close

        Tempfile.create('sftp-glob-txt') do |txt_local|
          txt_local.write('txt')
          txt_local.flush
          txt_local.close

          config.put(csv_local.path, csv_remote)
          config.put(txt_local.path, txt_remote)
        end
      end

      matches = config.connect { |connection| connection.dir.glob(remote_dir, '*.csv') }
      expect(matches.map(&:name)).to eq(['export.csv'])
    end
  end
end

RSpec.describe Health::ImportConfigPassword, type: :model do
  describe '#connect' do
    let(:config) { build(:mhx_sftp_credentials, host: 'sftp.example.com:8022', password: 'secret') }
    let(:connection) { instance_double(Sftp::Cli) }

    it 'opens an SFTP connection with config credentials' do
      expect(Sftp::Cli).to receive(:start).with(
        'sftp.example.com',
        config.username,
        password: config.password,
        port: 8022,
        skip_verify_host_key: true,
      ).and_yield(connection)

      yielded = nil
      config.connect { |conn| yielded = conn }
      expect(yielded).to eq(connection)
    end
  end
end
