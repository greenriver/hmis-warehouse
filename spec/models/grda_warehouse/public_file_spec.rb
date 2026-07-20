###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::PublicFile, type: :model do
  def valid_attributes(overrides = {})
    {
      name: 'client/hmis_consent',
      content: 'x' * 200,
      content_type: 'application/pdf',
    }.merge(overrides)
  end

  it 'is valid with an allowed content type and acceptable size' do
    file = described_class.new(valid_attributes)
    expect(file).to be_valid
  end

  it 'is invalid with a disallowed content type' do
    file = described_class.new(valid_attributes(content_type: 'application/zip'))
    expect(file).not_to be_valid
    expect(file.errors[:file]).to include('File type not allowed')
  end

  it 'is invalid when content is missing' do
    file = described_class.new(valid_attributes(content: nil))
    expect(file).not_to be_valid
    expect(file.errors[:file]).to include('No uploaded file found')
  end

  it 'is invalid when content exceeds 4 megabytes' do
    file = described_class.new(valid_attributes(content: 'x' * (4.megabytes + 1)))
    expect(file).not_to be_valid
    expect(file.errors[:file]).to include('File size should be less than 4 MB')
  end
end
