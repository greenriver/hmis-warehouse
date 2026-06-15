###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::UserAuthenticationSource, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it 'requires connector_id' do
      record = described_class.new(user: user, connector_user_id: 'uid-1')
      expect(record).not_to be_valid
      expect(record.errors[:connector_id]).to be_present
    end

    it 'requires connector_user_id' do
      record = described_class.new(user: user, connector_id: 'idp-1')
      expect(record).not_to be_valid
      expect(record.errors[:connector_user_id]).to be_present
    end

    it 'enforces uniqueness of connector_id scoped to connector_user_id' do
      described_class.create!(user: user, connector_id: 'idp-1', connector_user_id: 'uid-1')
      duplicate = described_class.new(user: user, connector_id: 'idp-1', connector_user_id: 'uid-1')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:connector_id]).to be_present
    end

    it 'allows the same connector_id with a different connector_user_id' do
      described_class.create!(user: user, connector_id: 'idp-1', connector_user_id: 'uid-1')
      other = described_class.new(user: create(:user), connector_id: 'idp-1', connector_user_id: 'uid-2')
      expect(other).to be_valid
    end
  end

  describe '#service_config' do
    it 'resolves the active config sharing its connector_id' do
      config = create(:idp_service_config, provider: 'keycloak', connector_id: 'keycloak-staff', keycloak_realm: 'staff')
      source = described_class.create!(user: user, connector_id: 'keycloak-staff', connector_user_id: 'uid-1')

      expect(source.service_config).to eq(config)
      expect(source.service_config.keycloak_realm).to eq('staff')
    end

    it 'is nil when no managed config matches the connector_id' do
      source = described_class.create!(user: user, connector_id: 'okta', connector_user_id: 'uid-1')
      expect(source.service_config).to be_nil
    end
  end

  describe 'soft delete and uniqueness' do
    it 'allows a new record with the same pair after the original is soft-deleted' do
      record = described_class.create!(user: user, connector_id: 'idp-1', connector_user_id: 'uid-1')
      record.destroy

      new_record = described_class.new(user: user, connector_id: 'idp-1', connector_user_id: 'uid-1')
      expect(new_record).to be_valid
    end
  end
end
