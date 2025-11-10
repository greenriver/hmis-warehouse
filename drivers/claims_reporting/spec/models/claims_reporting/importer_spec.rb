# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClaimsReporting::Importer do
  let(:importer) { described_class.new }

  describe '#import_from_zip' do
    let(:zip_path) { Rails.root.join('drivers', 'claims_reporting', 'spec', 'fixtures', 'test_claims.zip') }
    let(:fixtures_dir) { Rails.root.join('drivers', 'claims_reporting', 'spec', 'fixtures') }

    let(:member_roster_csv) do
      headers = ['member_id', 'nam_first', 'nam_last', 'sex', 'date_of_birth', 'enrolled_flag', 'last_office_visit', 'last_ed_visit', 'last_ip_visit', 'cp_claim_dt']
      data = [
        ['test1234', 'Test', 'User', 'M', '1980-01-01', 'Y', '2024-03-20', '2024-03-15', '2024-03-10', '2024-03-05'],
      ]

      CSV.generate(col_sep: '|') do |csv|
        csv << headers
        data.each { |row| csv << row }
      end
    end

    before do
      FileUtils.mkdir_p(fixtures_dir)
      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        zipfile.get_output_stream('member_roster.csv') { |f| f.write(member_roster_csv) }
      end
    end

    after do
      FileUtils.rm_f(zip_path)
      ClaimsReporting::MemberRoster.where(member_id: 'test1234').delete_all
    end

    shared_examples 'imports data from zip' do |replace_all|
      let(:import) do
        ClaimsReporting::Import.create!(
          source_url: "file://#{zip_path}",
          started_at: Time.current,
          importer: 'ClaimsReporting::Importer',
          method: 'import_from_zip',
          args: { replace_all: replace_all },
        )
      end

      before do
        importer.instance_variable_set(:@import, import)
      end

      it "imports with replace_all: #{replace_all}" do
        results = importer.import_from_zip(zip_path, new_import: false, replace_all: replace_all)
        expect(results.keys).to include('member_roster.csv')
        expect(results['member_roster.csv'][:records_read]).to be > 0
      end
    end

    it_behaves_like 'imports data from zip', true
    it_behaves_like 'imports data from zip', false
  end

  describe '#using_sftp' do
    let(:credentials) do
      {
        'host' => 'sftp.example.org',
        'username' => 'claims_user',
        'password' => 'super-secret',
      }
    end
    let(:expected_kex) do
      %w[
        curve25519-sha256@libssh.org
        ecdh-sha2-nistp521
        ecdh-sha2-nistp384
        ecdh-sha2-nistp256
        diffie-hellman-group-exchange-sha256
        diffie-hellman-group14-sha256
        diffie-hellman-group14-sha1
      ]
    end
    let(:connection) { instance_double(Net::SFTP::Session) }

    it 'configures Net::SFTP with the expected kex algorithms' do
      expect(Net::SFTP).to receive(:start) do |host, username, options|
        expect(host).to eq(credentials['host'])
        expect(username).to eq(credentials['username'])
        expect(options[:kex]).to eq(expected_kex)
        expect(options[:auth_methods]).to eq(%w[publickey password])
        expect(options[:password]).to eq(credentials['password'])
        connection
      end.and_yield(connection)

      importer.send(:using_sftp, credentials) do |sftp|
        expect(sftp).to eq(connection)
      end
    end
  end
end
