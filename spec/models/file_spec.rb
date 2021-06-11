require 'mini_magick'

RSpec.describe File do
  it 'does sane things with tmp files' do
    test_path = 'spec/fixtures/files/images/test_photo.jpg'
    tmp_path = '/tmp/test_photo.jpg'
    `cp #{test_path} #{tmp_path}`

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

        puts output
      end
    end
  end
end
