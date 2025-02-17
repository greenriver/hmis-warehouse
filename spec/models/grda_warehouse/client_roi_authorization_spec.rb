require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientRoiAuthorization, type: :model do
  let(:authorization) { create(:client_roi_authorization) }
  let(:today) { Date.current }

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

  describe '#matches_coc_codes?' do
    context 'when coc_codes is blank' do
      before { authorization.coc_codes = nil }

      it 'returns true' do
        expect(authorization.matches_coc_codes?(['ANY'])).to be true
      end
    end

    context 'when coc_codes are present' do
      before { authorization.coc_codes = ['CODE1', 'CODE2'] }

      it 'returns true when there is an intersection' do
        expect(authorization.matches_coc_codes?(['CODE1', 'CODE3'])).to be true
      end

      it 'returns false when there is no intersection' do
        expect(authorization.matches_coc_codes?(['CODE3', 'CODE4'])).to be false
      end
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
