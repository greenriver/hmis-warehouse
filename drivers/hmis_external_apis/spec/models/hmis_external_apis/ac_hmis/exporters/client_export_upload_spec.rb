###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::ClientExportUploader, type: :model do
  let(:subject) { HmisExternalApis::AcHmis::Exporters::ClientExportUploader.new(io_streams: [OpenStruct.new(name: 'Client.csv', io: StringIO.new("a,b,c\n1,2,3"))], date: Date.parse('2023-06-01')) }
  let(:creds) do
    # port = ENV['CI'].present? ? 2222 : 22

    GrdaWarehouse::RemoteCredentials::Sftp.create!(
      slug: 'ac_hmis_client_export',
      username: 'user',
      password: 'password',
      path: 'sftp',
      host: 'hmis-warehouse-sftp',
      port: 22,
    )
  end

  it 'uses a filename that starts with YYYY-MM-DD' do
    expect(subject.filename).to match(/^2023-06-01.+\.zip/)
  end

  it 'uploads to a remote server using credentials' do
    creds
    subject.run!

    file = '/tmp/2023-06-01-clients.zip'
    FileUtils.rm_f(file)
    args = { password: creds.password, verbose: :error }
    Net::SFTP.start(creds.host, creds.username, args) do |sftp|
      sftp.download!(creds.path + '/2023-06-01-clients.zip', file)
    end
    expect(File.exist?(file)).to be_truthy
  rescue SocketError => e
    raise "Did you start a testing sftp service? #{e.message}"
  end

  it 'compresses the file' do
    header = subject.send(:zipped_io_stream).string.first(2)
    expect(header).to eq('PK')
  end

  it 'has Client.csv in it' do
    io = subject.send(:zipped_io_stream)

    Zip::InputStream.open(io) do |zipfile|
      while (csv = zipfile.get_next_entry)
        next unless csv.file?

        expect(csv.name).to eq('Client.csv')
        expect(zipfile.read).to eq("a,b,c\n1,2,3")
      end
    end
  end
end
