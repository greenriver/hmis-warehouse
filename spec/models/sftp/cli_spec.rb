###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# CI provides an SFTP service for the test job (see hmis-warehouse-sftp in
# .github/workflows/rails_tests.yml). These examples stub Open3 and do not need it.
# To exercise SFTP against a local container instead: docker compose up -d sftp

require 'rails_helper'

RSpec.describe Sftp::Cli, type: :model do
  subject(:cli) do
    described_class.new('host.example.com', 'user', password: 'secret', skip_verify_host_key: true)
  end

  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  describe '.start' do
    it 'yields a connection and removes the password file afterward' do
      password_path = nil
      allow(Open3).to receive(:capture2e).and_return(['', success_status])

      described_class.start('host.example.com', 'user', password: 'secret', skip_verify_host_key: true) do |connection|
        connection.debug_command
        password_path = connection.instance_variable_get(:@password_file).path
        expect(File.exist?(password_path)).to be(true)
      end

      expect(File.exist?(password_path)).to be(false)
    end
  end

  describe '#debug_command' do
    it 'includes password auth, host, and host key skipping' do
      command = cli.debug_command
      expect(command).to include('sshpass')
      expect(command).to include('user@host.example.com')
      expect(command).to include('StrictHostKeyChecking=no')
    end
  end

  describe '#upload!' do
    it 'runs put with escaped paths' do
      expect(Open3).to receive(:capture2e) do |*_args, **kwargs|
        expect(kwargs[:stdin_data]).to include('put /local/export.csv /remote/export.csv')
        ['', success_status]
      end

      cli.upload!('/local/export.csv', '/remote/export.csv')
    end

    it 'raises when the sftp process fails' do
      allow(Open3).to receive(:capture2e).and_return(['connection refused', failure_status])

      expect { cli.upload!('/local/export.csv', '/remote/export.csv') }.to(
        raise_error(Sftp::Cli::StatusException, /SFTP command failed/),
      )
    end
  end

  describe '#download!' do
    it 'runs get for a single file' do
      expect(Open3).to receive(:capture2e) do |*_args, **kwargs|
        expect(kwargs[:stdin_data]).to include('get /remote/export.csv /local/export.csv')
        ['', success_status]
      end

      cli.download!('/remote/export.csv', '/local/export.csv')
    end

    it 'runs recursive get when requested' do
      expect(Open3).to receive(:capture2e) do |*_args, **kwargs|
        expect(kwargs[:stdin_data]).to include('get -r /remote/dir /local/dir')
        ['', success_status]
      end

      cli.download!('/remote/dir', '/local/dir', recursive: true)
    end
  end

  describe '#remove' do
    it 'runs rm on the remote path' do
      expect(Open3).to receive(:capture2e) do |*_args, **kwargs|
        expect(kwargs[:stdin_data]).to include('rm /remote/export.csv')
        ['', success_status]
      end

      cli.remove('/remote/export.csv')
    end
  end

  describe '#mkdir_p!' do
    it 'does not open a connection for the filesystem root' do
      expect(Open3).not_to receive(:capture2e)
      cli.mkdir_p!('/')
    end

    it 'runs mkdir for each path segment in one session' do
      expect(Open3).to receive(:capture2e) do |*_args, **kwargs|
        stdin = kwargs[:stdin_data]
        expect(stdin).to include('mkdir /sftp')
        expect(stdin).to include('mkdir /sftp/carehub_export')
        expect(stdin).to include('mkdir /sftp/carehub_export/2026-06-23')
        expect(stdin).to end_with("quit\n")
        ['', success_status]
      end

      cli.mkdir_p!('/sftp/carehub_export/2026-06-23')
    end

    it 'ignores failures when the directory already exists' do
      output = "remote mkdir \"/sftp\": Failure\n"
      allow(Open3).to receive(:capture2e).and_return([output, success_status])

      expect { cli.mkdir_p!('/sftp/new_dir') }.not_to raise_error
    end

    it 'raises when mkdir hits a non-recoverable error' do
      output = "dest open \"/sftp\": Permission denied\n"
      allow(Open3).to receive(:capture2e).and_return([output, success_status])

      expect { cli.mkdir_p!('/sftp') }.to raise_error(Sftp::Cli::StatusException, /mkdir_p failed/)
    end

    it 'raises when the sftp process exits unsuccessfully' do
      allow(Open3).to receive(:capture2e).and_return(['connection refused', failure_status])

      expect { cli.mkdir_p!('/sftp/new_dir') }.to raise_error(Sftp::Cli::StatusException, /mkdir_p failed/)
    end
  end

  describe '#dir' do
    let(:ls_output) do
      <<~OUTPUT
        export.csv
        ignored.txt
        sftp> quit
      OUTPUT
    end

    before do
      allow(cli).to receive(:execute_sftp_with_output).and_return(ls_output)
    end

    it 'glob filters remote filenames by pattern' do
      files = cli.dir.glob('/exports', '*.csv')
      expect(files.map(&:name)).to eq(['export.csv'])
    end

    it 'matches glob patterns against filenames' do
      regex = cli.dir.send(:glob_to_regex, '*.csv')
      expect('export.csv').to match(regex)
      expect('notes.txt').not_to match(regex)
    end

    it 'foreach parses ls -la output into entries' do
      long_output = <<~OUTPUT
        -rw-r--r--    1 user    group        1234 Jun 23 14:32 export.csv
        sftp> quit
      OUTPUT
      allow(cli).to receive(:execute_sftp_with_output).and_return(long_output)

      entries = []
      cli.dir.foreach('/exports') { |entry| entries << entry }
      expect(entries.map(&:name)).to eq(['export.csv'])
      expect(entries.first.longname).to include('export.csv')
    end
  end

  describe '#file' do
    before do
      allow(cli).to receive(:upload!)
    end

    it 'buffers writes and uploads on close' do
      cli.file.open('/remote/report.csv', 'w') { |f| f.write('csv data') }

      expect(cli).to have_received(:upload!).with(String, '/remote/report.csv')
    end

    it 'does not implement read mode' do
      expect { cli.file.open('/remote/report.csv', 'r') }.to raise_error(NotImplementedError)
    end
  end

  describe '#mkdir_p_commands' do
    it 'builds absolute path segments' do
      commands = cli.send(:mkdir_p_commands, '/sftp/carehub_export/2026-06-23')
      expect(commands).to eq(
        [
          'mkdir /sftp',
          'mkdir /sftp/carehub_export',
          'mkdir /sftp/carehub_export/2026-06-23',
        ],
      )
    end

    it 'builds relative path segments' do
      commands = cli.send(:mkdir_p_commands, 'carehub/export')
      expect(commands).to eq(['mkdir carehub', 'mkdir carehub/export'])
    end

    it 'returns no commands for blank paths' do
      expect(cli.send(:mkdir_p_commands, '')).to eq([])
      expect(cli.send(:mkdir_p_commands, '.')).to eq([])
    end
  end
end
