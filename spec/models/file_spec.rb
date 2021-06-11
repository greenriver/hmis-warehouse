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

    File.open(test_path, binmode: true) do |file|
      Tempfile.new(["mini_magick", '.jpg']).tap do |tempfile|
        tempfile.binmode

        IO.copy_stream(file, tempfile)

        output = MiniMagick::Tool::Identify.new do |cmd|
          cmd << tempfile.path
        end

        expect(output).to include('JPEG')

        puts output

        tempfile.close
      end
    end

    File.open(tmp_path, binmode: true) do |file|
      Tempfile.new(["mini_magick", '.jpg']).tap do |tempfile|
        tempfile.binmode

        IO.copy_stream(file, tempfile)

        # https://github.com/docker/for-linux/issues/1015 work around
        tempfile.close
        tempfile.chmod tempfile.lstat.mode

        output = MiniMagick::Tool::Identify.new do |cmd|
          cmd << tempfile.path
        end

        expect(output).to include('JPEG')

        puts output
      end
    end
  end
end
