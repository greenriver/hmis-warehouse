ENV['RAILS_ENV'] ||= 'test'
require_relative '../../config/boot'
require 'rails/all'
Bundler.require(*Rails.groups)

RSpec.describe File do
  it 'does sane things with tmp files' do
    test_path = 'spec/fixtures/files/images/test_photo.jpg'
    tmp_path = '/tmp/test_photo.jpg'
    `cp #{test_path} #{tmp_path}`

    # same bytes
    src_data = File.open(test_path, 'rb', &:read)
    dst_data = File.open(tmp_path, 'rb', &:read)
    expect(dst_data).to eq(src_data)

    # file magic groks them
    filemagic = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
    src_type = filemagic.buffer(src_data)
    expect(src_type).to eq('image/jpeg')
    dst_type = filemagic.buffer(dst_data)
    expect(dst_type).to eq(src_type)

    # image magic does too
    expect(MiniMagick::Image.new(test_path).mime_type).to eq('image/jpeg')
    expect(MiniMagick::Image.new(tmp_path).mime_type).to eq('image/jpeg')

    output = MiniMagick::Tool::Identify.new do |cmd|
      cmd << tmp_path
    end
    expect(output).to include('JPEG')

    File.open(tmp_path, binmode: true) do |file|
      Tempfile.new(["mini_magick", '.jpg']).tap do |tempfile|
        tempfile.binmode

        IO.copy_stream(file, tempfile)

        tempfile.close

        output = MiniMagick::Tool::Identify.new do |cmd|
          cmd << tempfile.path
        end

        expect(output).to include('JPEG')
      end
    end
  end
end
