###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HealthEmergency::TestBatch, type: :model do
  let(:xlsx_bytes) { File.binread(Rails.root.join('spec/fixtures/files/health_emergency/test_results.xlsx')) }
  let(:xlsx_content_type) { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }

  def build_batch(content: xlsx_bytes, content_type: xlsx_content_type)
    described_class.new(name: 'batch.xlsx', content_type: content_type, content: content)
  end

  describe '#validate_file_content_if_present' do
    it 'has no file-content error for a valid xlsx' do
      batch = build_batch
      batch.valid?
      expect(batch.errors[:file]).to be_empty
    end

    it 'is a no-op when content is blank' do
      batch = build_batch(content: nil, content_type: nil)
      batch.valid?
      expect(batch.errors[:file]).to be_empty
    end

    it 'adds a file-content error for content that is not a valid xlsx' do
      batch = build_batch(content: "<html><body>not a spreadsheet</body></html>\n", content_type: 'text/html')
      batch.valid?
      expect(batch.errors[:file]).to be_present
    end
  end
end
