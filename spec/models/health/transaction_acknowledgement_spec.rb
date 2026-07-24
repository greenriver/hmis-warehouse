###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::TransactionAcknowledgement, type: :model do
  let(:bytes) { "ISA*00* ... 999 payload ... ~\n" }

  def build_ack
    described_class.new(original_filename: '999.edi', content: bytes)
  end

  describe '#file_data' do
    it 'returns content, then attachment when migrated' do
      ack = build_ack
      expect(ack.file_data).to eq(bytes)
      ack.content = nil
      ack.save!(validate: false)
      ack.acknowledgement_file.attach(io: StringIO.new(bytes), filename: '999.edi', content_type: 'text/plain')
      expect(ack.file_data).to eq(bytes)
    end
  end

  describe '#copy_to_s3!' do
    it 'attaches and nulls content' do
      ack = build_ack
      ack.save!(validate: false)
      ack.copy_to_s3!
      ack.reload
      expect(ack.acknowledgement_file).to be_attached
      expect(ack.acknowledgement_file.download).to eq(bytes)
      expect(ack.content).to be_nil
    end
  end

  describe '.unprocessed_s3_migration' do
    it 'excludes already-attached records and includes pending content-only records' do
      attached = build_ack
      attached.save!(validate: false)
      attached.acknowledgement_file.attach(io: StringIO.new(bytes), filename: '999.edi', content_type: 'text/plain')

      pending = build_ack
      pending.save!(validate: false)

      ids = described_class.unprocessed_s3_migration.pluck(:id)
      expect(ids).to include(pending.id)
      expect(ids).not_to include(attached.id)
    end
  end
end
