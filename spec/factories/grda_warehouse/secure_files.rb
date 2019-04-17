# include ActionDispatch::TestProcess
FactoryGirl.define do
  factory :secure_file, class: 'GrdaWarehouse::SecureFile' do
    name { 'test file' }
    content { File.open('spec/fixtures/files/images/test_photo.jpg', 'r') }
    # after :create do |b|
    #   b.update_column(:file, 'spec/fixtures/files/test_photo.jpg')
    # end

    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg') }
    # file { fixture_file_upload(Rails.root.join('spec/fixtures/files/images/'), 'image/jpeg') }
    # f.file { Rack::Test::UploadedFile.new(File.join(Rails.root.join('spec', 'fixtures', 'files', 'images'), 'test_photo.jpg'), 'image/jpeg')}
    # f.file
    # f.file File.open('spec/fixtures/files/images/test_photo.jpg', 'r')
  end
end