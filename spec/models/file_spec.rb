RSpec.describe File do
  it 'has a safe place to work' do
    filemagic = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)

    test_path = 'spec/fixtures/files/images/test_photo.jpg'
    tmp_path = '/tmp/test_photo.jpg'
    `cp #{test_path} #{tmp_path}`

    src_data = File.open(test_path, 'rb', &:read)
    dst_data = File.open(tmp_path, 'rb', &:read)
    expect(dst_data).to eq(src_data)

    src_type = filemagic.buffer(src_data)
    expect(src_type).to eq('image/jpeg')

    dst_type = filemagic.buffer(dst_data)
    expect(dst_type).to eq(src_type)
  end

  it 'has a safe place to work' do
    test_path = 'spec/fixtures/files/images/test_photo.jpg'
    tmp_path = '/tmp/test_photo.jpg'
    `cp #{test_path} #{tmp_path}`
    src_data = File.open(test_path, 'rb', &:read)
    dst_data = 'x'+File.open(tmp_path, 'rb', &:read)

    expect(dst_data).to eq(src_data)
  end
end
