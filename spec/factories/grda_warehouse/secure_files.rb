FactoryBot.define do
  factory :secure_file, class: 'GrdaWarehouse::SecureFile' do
    name { 'test file' }
    file {  Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg') }
    content { file.read }
  end
end
