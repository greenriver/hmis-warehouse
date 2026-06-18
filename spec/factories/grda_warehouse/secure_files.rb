###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :secure_file, class: 'GrdaWarehouse::SecureFile' do
    name { 'test file' }

    # Files are stored via ActiveStorage (see SecureFilesController#create); the
    # show action serves the attachment directly. Attach a fixture so the created
    # record matches a real upload.
    after(:build) do |secure_file|
      secure_file.secure_file.attach(
        io: StringIO.new(File.binread(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'))),
        filename: 'test_photo.jpg',
        content_type: 'image/jpeg',
      )
    end
  end
end
