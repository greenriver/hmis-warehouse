# include ActionDispatch::TestProcess
SECURE_FILE_UPLOAD_FIXTURE ||= begin
  Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg').tap do |f|
    # https://github.com/docker/for-linux/issues/1015 work around
    io = f.tempfile
    io.chmod io.lstat.mode
  end
end

FactoryBot.define do
  factory :secure_file, class: 'GrdaWarehouse::SecureFile' do
    name { 'test file' }
    file {  SECURE_FILE_UPLOAD_FIXTURE }
  end
end
