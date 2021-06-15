# include ActionDispatch::TestProcess
require 'docker_fs_fix'

SECURE_FILE_UPLOAD_FIXTURE ||= begin
  DockerFsFix.upload Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg')
end

FactoryBot.define do
  factory :secure_file, class: 'GrdaWarehouse::SecureFile' do
    name { 'test file' }
    file {  SECURE_FILE_UPLOAD_FIXTURE }
  end
end
