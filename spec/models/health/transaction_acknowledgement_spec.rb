###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::TransactionAcknowledgement, type: :model do
  let(:edi) { "ISA*00*          *00*          *ZZ*SUBMITTERID    *ZZ*RECEIVERID     *200101*1200*^*00501*000000001*0*P*:~\n" }

  def build_ack(content)
    described_class.new(original_filename: '999.edi', content: content)
  end

  describe 'file content validation' do
    it 'accepts EDI content' do
      expect(build_ack(edi)).to be_valid
    end

    it 'rejects content that is not EDI' do
      ack = build_ack("%PDF-1.4\nnot an EDI file\n")
      expect(ack).not_to be_valid
      expect(ack.errors[:file]).to be_present
    end

    it 'rejects content over the size limit' do
      ack = build_ack('ISA' + ('x' * 26.megabytes))
      expect(ack).not_to be_valid
      expect(ack.errors[:file].join).to match(/too large/)
    end

    it 'is valid without content' do
      expect(build_ack(nil)).to be_valid
    end
  end

  describe 'storage' do
    it 'keeps the file contents in the database' do
      ack = build_ack(edi)
      ack.save!
      expect(ack.reload.content).to eq(edi)
    end
  end

  describe 'parsing' do
    it 'reads from the content column' do
      ack = build_ack(edi)
      expect(ack.parse_999).to be_present
    end

    it 'returns an error result when the payload is not a complete 999' do
      expect(build_ack(edi).transaction_result).to eq('error')
    end
  end
end
