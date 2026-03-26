###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Model spec for the Hmis::ClientSearchQuery model, used for tracking user searches so we avoid putting PII in the URL.
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

    it 'reuses the existing row when params differ only by key order' do
      canonical = { 'first_name' => 'a', 'last_name' => 'b' }
      existing = create(:hmis_client_search_query, created_by: hmis_user, params: canonical)

      expect do
        result = described_class.find_or_create_by_params(
          { 'last_name' => 'b', 'first_name' => 'a' },
          user: hmis_user,
        )
        expect(result.id).to eq(existing.id)
        expect(result.params).to eq(canonical)
      end.not_to change(described_class, :count)
    end
  end

  describe '.normalize_params' do
    it 'sorts keys and array elements so equivalent inputs match' do
      # `some_list` is not a supported param, but used only in this test to confirm normalization of arrays (in case of future array params)
      a = described_class.normalize_params({ 'last_name' => 'b', 'some_list' => ['3', '1', '2'], 'first_name' => 'a' })
      b = described_class.normalize_params({ 'first_name' => 'a', 'some_list' => ['2', '3', '1'], 'last_name' => 'b' })
      expect(a).to eq(b)
      expect(described_class.generate_fingerprint(a)).to eq(described_class.generate_fingerprint(b))
    end
  end
end
