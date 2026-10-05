###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientRoiAuthorization, type: :model do
  let(:authorization) { create(:client_roi_authorization) }
  let(:today) { Date.current }

  describe '.active' do
    let!(:active_partial) { create(:client_roi_authorization, status: described_class::PARTIAL_STATUS) }
    let!(:active_full) { create(:client_roi_authorization, status: described_class::FULL_STATUS) }
    let!(:revoked) { create(:client_roi_authorization, status: described_class::REVOKED_STATUS) }
    let!(:expired) { create(:client_roi_authorization, status: described_class::FULL_STATUS, expires_at: today - 1.day) }
    let!(:future) { create(:client_roi_authorization, status: described_class::FULL_STATUS, starts_at: today + 1.day) }
    let!(:within_range) { create(:client_roi_authorization, status: described_class::FULL_STATUS, starts_at: today - 1.day, expires_at: today + 1.day) }

    it 'returns only active authorizations for today' do
      expect(described_class.active).to contain_exactly(active_partial, active_full, within_range)
    end

    it 'returns active authorizations for a specific date' do
      expect(described_class.active(today + 2.days)).to contain_exactly(active_partial, active_full, future)
    end
  end

  context 'when status is revoked' do
    before { authorization.status = described_class::REVOKED_STATUS }

    it 'returns false' do
      expect(authorization.active?).to be false
    end
  end

  context 'when status is partial' do
    before { authorization.status = described_class::PARTIAL_STATUS }

    it 'returns true' do
      expect(authorization.active?).to be true
    end
  end

  context 'when status is full' do
    before { authorization.status = described_class::FULL_STATUS }

    it 'returns true' do
      expect(authorization.active?).to be true
    end
  end

  describe '#date_in_valid_range?' do
    context 'with both starts_at and expires_at' do
      before do
        authorization.starts_at = today - 1.day
        authorization.expires_at = today + 1.day
      end

      it 'returns true when date is within range' do
        expect(authorization.date_in_valid_range?(today)).to be true
      end

      it 'returns false when date is outside range' do
        expect(authorization.date_in_valid_range?(today + 2.days)).to be false
      end

      it 'returns false when date is outside range' do
        expect(authorization.date_in_valid_range?(today - 2.days)).to be false
      end
    end

    context 'with only expires_at' do
      before { authorization.expires_at = today + 1.day }

      it 'returns true when date is before expiry' do
        expect(authorization.date_in_valid_range?(today)).to be true
      end

      it 'returns false when date is after expiry' do
        expect(authorization.date_in_valid_range?(today + 2.days)).to be false
      end
    end
  end

  describe '.visible_in_cocs' do
    def use_config(factory)
      GrdaWarehouse::Config.delete_all
      create(factory)
      GrdaWarehouse::Config.invalidate_cache
    end

    let!(:full) { create(:client_roi_authorization, status: 'full') }
    let!(:partial) { create(:client_roi_authorization, status: 'partial') }
    let!(:revoked) { create(:client_roi_authorization, status: 'revoked') }
    let!(:expired) { create(:client_roi_authorization, status: 'full', expires_at: Date.yesterday) }
    let!(:expires_today) { create(:client_roi_authorization, status: 'full', expires_at: Date.current) }
    let!(:not_started) { create(:client_roi_authorization, status: 'full', starts_at: Date.tomorrow) }
    let!(:empty_cocs) { create(:client_roi_authorization, status: 'full', coc_codes: []) }
    let!(:all_cocs) { create(:client_roi_authorization, status: 'full', coc_codes: ['All CoCs']) }
    let!(:co_500) { create(:client_roi_authorization, status: 'full', coc_codes: ['CO-500']) }

    it 'returns full releases in effect today for any CoC under Consent::Default' do
      use_config(:config_b)
      expect(described_class.visible_in_cocs([]).pluck(:id)).to contain_exactly(full.id, expires_today.id, empty_cocs.id, all_cocs.id)
    end

    it 'includes a release limited to a CoC the user has' do
      use_config(:config_b)
      expect(described_class.visible_in_cocs(['CO-500', 'PA-501']).pluck(:id)).to contain_exactly(full.id, expires_today.id, empty_cocs.id, all_cocs.id, co_500.id)
    end

    it 'includes partial rows under Consent::Implied' do
      use_config(:config_va)
      expect(described_class.visible_in_cocs([]).pluck(:id)).to contain_exactly(full.id, partial.id, expires_today.id, empty_cocs.id, all_cocs.id)
    end

    it 'treats a CoC code containing a quote as a literal value' do
      use_config(:config_b)
      quoted = create(:client_roi_authorization, status: 'full', coc_codes: ["CO-5'00"])
      expect(described_class.visible_in_cocs(["CO-5'00"]).pluck(:id)).to include(quoted.id)
    end
  end

  describe '.with_consenting_source' do
    let(:consenting_ds) { create :source_data_source, obey_consent: true }
    let(:non_consenting_ds) { create :source_data_source, obey_consent: false }
    let(:destination_ds) { create :destination_data_source }

    def destination_with_source(source_ds)
      destination = create :hud_client, data_source: destination_ds
      source = create :hud_client, data_source: source_ds
      create :warehouse_client, source_id: source.id, destination_id: destination.id
      destination
    end

    let!(:consenting) { create :client_roi_authorization, destination_client: destination_with_source(consenting_ds) }
    let!(:non_consenting) { create :client_roi_authorization, destination_client: destination_with_source(non_consenting_ds) }
    let!(:no_sources) { create :client_roi_authorization, destination_client: create(:hud_client, data_source: destination_ds) }

    it 'keeps only rows whose destination has a source client in a data source that obeys consent' do
      expect(described_class.with_consenting_source).to contain_exactly(consenting)
    end

    it 'keeps a row when any one of several sources obeys consent' do
      extra_source = create :hud_client, data_source: non_consenting_ds
      create :warehouse_client, source_id: extra_source.id, destination_id: consenting.destination_client_id
      expect(described_class.with_consenting_source).to contain_exactly(consenting)
    end
  end

  describe 'when clients are merged' do
    let!(:warehouse_client_1) { create(:warehouse_client) }
    let!(:warehouse_client_2) { create(:warehouse_client) }
    let!(:authorization_1) { create(:client_roi_authorization, destination_client: warehouse_client_1.destination) }
    let!(:authorization_2) { create(:client_roi_authorization, destination_client: warehouse_client_2.destination) }

    it 'deletes the authorization associated with the deleted client' do
      expect do
        warehouse_client_1.destination.merge_from(warehouse_client_2.destination, reviewed_by: User.system_user, reviewed_at: Time.current)
      end.to change { GrdaWarehouse::ClientRoiAuthorization.count }.by(-1)
    end

    it 'deletes the expected authorization' do
      warehouse_client_1.destination.merge_from(warehouse_client_2.destination, reviewed_by: User.system_user, reviewed_at: Time.current)
      expect(GrdaWarehouse::ClientRoiAuthorization.pluck(:id)).to eq([authorization_1.id])
    end
  end
end
