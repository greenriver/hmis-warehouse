###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSupplemental::DataSet, type: :model do
  let(:data_set) do
    create(:hmis_supplemental_data_set)
  end

  it 'validates for empty field config' do
    data_set.field_config = <<~JSON
      []
    JSON
    expect(data_set.save).to be(false)
    expect(data_set.errors.full_messages).to eq(['Field config root is invalid: error_type=minItems'])
  end

  it 'validates syntax errors in the config' do
    data_set.field_config = <<~JSON
      [{this won't parse, hopefully}]
    JSON
    expect(data_set.save).to be(false)
    expect(data_set.errors.full_messages).to contain_exactly(
      a_string_matching(/\AField config expected object key,*/),
    )
  end

  describe '.syncable' do
    let!(:syncable) { create(:hmis_supplemental_data_set, sync_enabled: true) }
    let!(:inactive_credential_set) do
      create(:hmis_supplemental_data_set, sync_enabled: true, remote_credential: create(:grda_remote_s3, active: false))
    end

    before { create(:hmis_supplemental_data_set, sync_enabled: false) }

    it 'returns every sync-enabled set, whether or not its credential is active' do
      expect(described_class.syncable).to contain_exactly(syncable, inactive_credential_set)
    end

    it 'returns nothing in sandbox mode' do
      with_sandbox_mode do
        expect(described_class.syncable).to be_empty
      end
    end
  end
end
