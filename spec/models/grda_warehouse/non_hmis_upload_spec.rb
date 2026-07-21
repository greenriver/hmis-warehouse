###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::NonHmisUpload, type: :model do
  let(:data_source) { create(:source_data_source) }

  def valid_attributes(overrides = {})
    {
      data_source: data_source,
      file: 'export.zip',
      content: 'x' * 200,
      content_type: 'application/zip',
    }.merge(overrides)
  end

  it 'is valid with a .zip filename' do
    upload = described_class.new(valid_attributes)
    expect(upload).to be_valid
  end

  it 'is valid with an uppercase .ZIP filename' do
    upload = described_class.new(valid_attributes(file: 'export.ZIP'))
    expect(upload).to be_valid
  end

  it 'is invalid with a non-.zip filename' do
    upload = described_class.new(valid_attributes(file: 'export.csv'))
    expect(upload).not_to be_valid
    expect(upload.errors[:file]).to include('must be a zip file')
  end

  it 'is invalid with a non-.zip filename disguised by a trailing .zip in the name' do
    upload = described_class.new(valid_attributes(file: 'malware.zip.exe'))
    expect(upload).not_to be_valid
    expect(upload.errors[:file]).to include('must be a zip file')
  end

  it 'is invalid without a file on create' do
    upload = described_class.new(valid_attributes(file: nil))
    expect(upload).not_to be_valid
    expect(upload.errors[:file]).to include("can't be blank")
  end

  it 'is invalid without a data_source' do
    upload = described_class.new(valid_attributes(data_source: nil))
    expect(upload).not_to be_valid
    expect(upload.errors[:data_source]).to include("can't be blank")
  end
end
