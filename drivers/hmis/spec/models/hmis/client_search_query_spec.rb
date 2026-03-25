###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::ClientSearchQuery, type: :model do
  let!(:ds1) { create :hmis_primary_data_source }
  let!(:ds2) { create :hmis_data_source }
  let!(:hmis_user) { create(:hmis_user, data_source: ds1) }

  let(:search_params) { { 'text_search' => 'lookup' } }

  describe '.find_or_create_by_params' do
    it 'returns an invalid instance without persisting when params are invalid' do
      result = described_class.find_or_create_by_params({ 'not_allowed' => 'x' }, user: hmis_user)
      expect(result).not_to be_persisted
      expect(result.errors[:params]).to be_present
    end

    it 'creates a new persisted query when none exists for this user and data source' do
      expect do
        result = described_class.find_or_create_by_params(search_params, user: hmis_user)
        expect(result).to be_persisted
        expect(result.params).to eq(search_params)
        expect(result.created_by_id).to eq(hmis_user.id)
        expect(result.data_source_id).to eq(ds1.id)
      end.to change(described_class, :count).by(1)
    end

    it 'reuses the existing row for the same params, user, and data source' do
      existing = create(:hmis_client_search_query, created_by: hmis_user, params: search_params)

      expect do
        result = described_class.find_or_create_by_params(search_params, user: hmis_user)
        expect(result.id).to eq(existing.id)
      end.not_to change(described_class, :count)
    end

    it 'refreshes stored params when they were out of sync with fingerprint (unexpected)' do
      existing = create(:hmis_client_search_query, created_by: hmis_user, params: search_params)
      stale_params = { 'text_search' => 'stale' }
      existing.update_columns(params: stale_params)

      expect do
        result = described_class.find_or_create_by_params(search_params, user: hmis_user)
        expect(result.id).to eq(existing.id)
        expect(result.params).to eq(search_params) # Updated to match the incoming search_params
      end.not_to change(described_class, :count)
    end

    it 'creates a separate row when another user searches with the same params on the same data source' do
      other_hmis_user = create(:hmis_user, data_source: ds1)
      create(:hmis_client_search_query, created_by: other_hmis_user, params: search_params)

      expect do
        result = described_class.find_or_create_by_params(search_params, user: hmis_user)
        expect(result.created_by_id).to eq(hmis_user.id)
        expect(result.data_source_id).to eq(ds1.id)
      end.to change(described_class, :count).by(1)
    end

    it 'does not reuse a row for the same user and params on a different data source' do
      existing = create(
        :hmis_client_search_query,
        created_by: hmis_user,
        params: search_params,
        data_source_id: ds2.id,
      )

      expect do
        result = described_class.find_or_create_by_params(search_params, user: hmis_user)
        expect(result.id).not_to eq(existing.id)
        expect(result.data_source_id).to eq(ds1.id)
      end.to change(described_class, :count).by(1)
    end

    it 'creates a new row when params differ' do
      create(:hmis_client_search_query, created_by: hmis_user, params: search_params)
      other_params = { 'text_search' => 'different' }

      expect do
        described_class.find_or_create_by_params(other_params, user: hmis_user)
      end.to change(described_class, :count).by(1)
    end
  end
end
