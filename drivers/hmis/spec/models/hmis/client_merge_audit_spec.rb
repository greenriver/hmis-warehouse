###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::ClientMergeAudit, type: :model do
  include_context 'hmis base setup'

  let(:actor) { create(:hmis_user) }
  let(:audit) do
    create(
      :hmis_client_merge_audit,
      actor: actor,
      merged_at: Time.current,
      pre_merge_mappings: {
        'enrollments' => {
          '100' => { 'PersonalID' => 'OLD_PERSONAL_ID_1' },
          '200' => { 'PersonalID' => 'OLD_PERSONAL_ID_2' },
        },
        'files' => {
          '50' => { 'client_id' => 999 },
        },
        'source_clients' => {
          '300' => { 'destination_id' => 888 },
        },
      },
    )
  end

  describe '#validate_pre_merge_mappings_structure' do
    it 'accepts valid mappings structure' do
      audit.send(:validate_pre_merge_mappings_structure)
      expect(audit.errors[:pre_merge_mappings]).to be_empty
    end

    it 'rejects invalid mappings structure' do
      audit.pre_merge_mappings = {
        'invalid_key' => { '1' => { 'some_field' => 'value' } },
        'enrollments' => { '123' => { 'client_id' => 'ABC123' } }, # wrong field
        'files' => { '456' => { 'PersonalID' => 789 } }, # wrong field
      }
      audit.send(:validate_pre_merge_mappings_structure)
      expect(audit.errors[:pre_merge_mappings]).to be_present
      expect(audit.errors[:pre_merge_mappings]).to include(/mapping keys invalid_key are unexpected/)
      expect(audit.errors[:pre_merge_mappings]).to include(/Invalid mapping structure for enrollments/)
      expect(audit.errors[:pre_merge_mappings]).to include(/Invalid mapping structure for files/)
    end
  end

  it 'returns mappings for a record type' do
    expect(audit.mappings_for('enrollments')[100]).to eq({ 'PersonalID' => 'OLD_PERSONAL_ID_1' })
    expect(audit.mappings_for('files')[50]).to eq({ 'client_id' => 999 })
  end

  it 'returns enrollment IDs' do
    expect(audit.enrollment_ids).to contain_exactly(100, 200)
  end

  it 'returns original PersonalID for an enrollment' do
    expect(audit.original_personal_id_for_enrollment(100)).to eq('OLD_PERSONAL_ID_1')
    expect(audit.original_personal_id_for_enrollment(200)).to eq('OLD_PERSONAL_ID_2')
  end

  it 'returns original client_id for a record' do
    expect(audit.original_client_id_for('files', 50)).to eq(999)
  end

  it 'returns original warehouse destination client ID' do
    expect(audit.original_warehouse_destination_id(300)).to eq(888)
  end
end
