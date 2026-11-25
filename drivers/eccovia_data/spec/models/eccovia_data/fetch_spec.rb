###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EccoviaData::Fetch, type: :model do
  describe '.with_active_credentials' do
    let(:data_source) { create(:grda_warehouse_data_source) }

    def create_credential(active:)
      EccoviaData::Credential.create!(
        active: active,
        username: 'key',
        password: 'secret',
        endpoint: 'https://eccovia.example.com',
        slug: "eccovia-#{SecureRandom.hex(4)}",
      )
    end

    def create_fetch(credentials:, active:)
      described_class.create!(credentials: credentials, data_source_id: data_source.id, active: active)
    end

    let!(:eligible) { create_fetch(credentials: create_credential(active: true), active: true) }

    before do
      create_fetch(credentials: create_credential(active: false), active: true)
      create_fetch(credentials: create_credential(active: true), active: false)
      deleted = create_fetch(credentials: create_credential(active: true), active: true)
      deleted.update_columns(deleted_at: Time.current)
    end

    it 'returns only active, undeleted fetches that have an active credential' do
      expect(described_class.with_active_credentials).to contain_exactly(eligible)
    end

    it 'returns nothing in sandbox mode' do
      with_sandbox_mode do
        expect(described_class.with_active_credentials).to be_empty
      end
    end
  end
end
