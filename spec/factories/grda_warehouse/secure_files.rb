###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :secure_file, class: 'GrdaWarehouse::SecureFile' do
    name { 'test file' }
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg') }
    content { file.read }
    # Legacy (pre-ActiveStorage) rows carry the content type captured at upload;
    # the show action's fallback branch passes it straight to send_data.
    content_type { 'image/jpeg' }
  end
end
