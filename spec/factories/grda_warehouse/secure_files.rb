# include ActionDispatch::TestProcess
FactoryBot.define do
  factory :secure_file, class: 'GrdaWarehouse::SecureFile' do
    name { 'test file' }
    content { File.open('spec/fixtures/files/images/test_photo.jpg', 'r') }

    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg') }
  end
end
