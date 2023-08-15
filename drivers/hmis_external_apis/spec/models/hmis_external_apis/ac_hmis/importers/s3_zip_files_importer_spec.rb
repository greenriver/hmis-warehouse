###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::S3ZipFilesImporter, type: :model do
  let(:bucket) { "bucket-#{SecureRandom.hex}" }
  let(:subject) { HmisExternalApis::AcHmis::Importers::S3ZipFilesImporter.new(bucket_name: bucket) }

  class FauxImporter
    def initialize(dir:, key:, etag:)
      _unused = [dir, key, etag]
      FileUtils.rm_f('/tmp/imported')
    end

    def run!
      FileUtils.touch('/tmp/imported')
    end
  end

  around(:each) do |each|
    create_bucket(bucket)
    each.run
    delete_bucket(bucket)
  end

  it 'Runs importer' do
    io = File.open('drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/data.zip', 'r')
    put_s3_object(io: io, bucket: bucket, key: 'data.zip')
    FileUtils.rm_f('/tmp/imported')

    subject.importer_class = FauxImporter
    subject.run!

    expect(File.exist?('/tmp/imported')).to be_truthy
  end

  it 'extracts files' do
    io = File.open('drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/data.zip', 'r')
    put_s3_object(io: io, bucket: bucket, key: 'data.zip')
    subject.run!
    expect(subject.found_csvs.to_set).to eq(['README', 'data.csv', 'data.dictionary.txt'].to_set)
  end
end
