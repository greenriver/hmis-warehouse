###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EccoviaData::Fetch, type: :model do
  describe '.outbound_allowed' do
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

    let!(:fetches) do
      [
        create_fetch(credentials: create_credential(active: true), active: true),
        create_fetch(credentials: create_credential(active: false), active: true),
        create_fetch(credentials: create_credential(active: true), active: false),
        create_fetch(credentials: create_credential(active: true), active: true).tap { |f| f.update_columns(deleted_at: Time.current) },
      ]
    end

    it 'returns every fetch regardless of active flags or deletion' do
      expect(described_class.outbound_allowed).to match_array(fetches)
    end

    it 'returns nothing in sandbox mode' do
      with_sandbox_mode do
        expect(described_class.outbound_allowed).to be_empty
      end
    end
  end
end
