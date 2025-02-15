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

  describe '.active' do
    let!(:revoked_auth) { create(:client_roi_authorization, status: described_class::REVOKED_STATUS) }
    let!(:partial_auth) { create(:client_roi_authorization, status: described_class::PARTIAL_STATUS) }
    let!(:full_auth) { create(:client_roi_authorization, status: described_class::FULL_STATUS) }
    let(:today) { Date.current }

    it 'excludes revoked authorizations' do
      expect(described_class.active).not_to include(revoked_auth)
    end

    it 'includes partial authorizations' do
      expect(described_class.active).to include(partial_auth)
    end

    it 'includes full authorizations' do
      expect(described_class.active).to include(full_auth)
    end

    context 'with date ranges' do
      let!(:expired_auth) do
        create(:client_roi_authorization,
          status: described_class::PARTIAL_STATUS,
          starts_at: today - 2.days,
          expires_at: today - 1.day)
      end

      let!(:future_auth) do
        create(:client_roi_authorization,
          status: described_class::PARTIAL_STATUS,
          starts_at: today + 1.day,
          expires_at: today + 2.days)
      end

      let!(:current_auth) do
        create(:client_roi_authorization,
          status: described_class::PARTIAL_STATUS,
          starts_at: today - 1.day,
          expires_at: today + 1.day)
      end

      let!(:starts_only_auth) do
        create(:client_roi_authorization,
          status: described_class::PARTIAL_STATUS,
          starts_at: today - 1.day,
          expires_at: nil)
      end

      let!(:expires_only_auth) do
        create(:client_roi_authorization,
          status: described_class::PARTIAL_STATUS,
          starts_at: nil,
          expires_at: today + 1.day)
      end

      it 'includes authorizations within their date range' do
        expect(described_class.active).to include(current_auth)
      end

      it 'excludes expired authorizations' do
        expect(described_class.active).not_to include(expired_auth)
      end

      it 'excludes future authorizations' do
        expect(described_class.active).not_to include(future_auth)
      end

      it 'includes authorizations with only starts_at if started' do
        expect(described_class.active).to include(starts_only_auth)
      end

      it 'includes authorizations with only expires_at if not expired' do
        expect(described_class.active).to include(expires_only_auth)
      end
    end
  end

  describe '.matching_coc_codes' do
    let!(:no_codes_auth) { create(:client_roi_authorization, coc_codes: nil) }
    let!(:with_codes_auth) { create(:client_roi_authorization, coc_codes: ['CODE1', 'CODE2']) }

    context 'when searching with any codes' do
      it 'includes authorizations with no coc_codes' do
        expect(described_class.matching_coc_codes(['ANY'])).to include(no_codes_auth)
      end
    end

    context 'when searching with matching codes' do
      it 'includes authorizations with matching codes' do
        expect(described_class.matching_coc_codes(['CODE1', 'CODE3']))
          .to include(with_codes_auth)
      end
    end

    context 'when searching with non-matching codes' do
      it 'excludes authorizations without matching codes' do
        expect(described_class.matching_coc_codes(['CODE3', 'CODE4']))
          .not_to include(with_codes_auth)
      end
    end
  end


end
