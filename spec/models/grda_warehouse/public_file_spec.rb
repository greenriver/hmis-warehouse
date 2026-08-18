###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::PublicFile, type: :model do
  let(:bytes) { ('a'..'z').to_a.join * 20 } # > 100 bytes, < 4 MB

  def build_file
    described_class.new(name: 'client/releases/coc_map', content_type: 'image/png', content: bytes)
  end

  describe '#file_data' do
    it 'returns content when not attached, attachment when attached' do
      file = build_file
      expect(file.file_data).to eq(bytes)

      file.content = nil
      file.save!(validate: false)
      file.public_file.attach(io: StringIO.new(bytes), filename: 'coc_map.png', content_type: 'image/png')
      expect(file.file_data).to eq(bytes)
    end
  end

  describe 'content type validation' do
    # The check must look at the bytes, not the client-supplied content_type
    # column, which can be spoofed.
    let(:png_bytes) { "\x89PNG\r\n\x1a\n".b + bytes.b }
    let(:html_bytes) { '<html><script>alert(1)</script></html>' + bytes }

    it 'rejects disallowed content types on create' do
      file = described_class.new(name: 'test', content_type: 'text/html')
      file.public_file.attach(io: StringIO.new(html_bytes), filename: 'x.html', content_type: 'text/html')
      expect(file).not_to be_valid
      expect(file.errors[:file]).to include('You are not allowed to upload text/html files')
    end

    it 'rejects bytes that disagree with an allowed claimed content type' do
      file = described_class.new(name: 'test', content_type: 'image/png')
      file.public_file.attach(io: StringIO.new(html_bytes), filename: 'x.png', content_type: 'image/png')
      expect(file).not_to be_valid
      expect(file.errors[:file]).to include('You are not allowed to upload text/html files')
    end

    it 'accepts an allowed content type on create' do
      file = described_class.new(name: 'test', content_type: 'image/png')
      file.public_file.attach(io: StringIO.new(png_bytes), filename: 'x.png', content_type: 'image/png')
      expect(file).to be_valid
    end

    it 'reports the byte-derived content type, not the claimed one' do
      file = described_class.new(name: 'test', content_type: 'image/png')
      file.public_file.attach(io: StringIO.new(html_bytes), filename: 'x.png', content_type: 'image/png')
      expect(file.detected_content_type).to eq('text/html')
    end
  end
end
