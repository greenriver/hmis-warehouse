###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Compliance::Agreement, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      agreement = build(:compliance_agreement)
      expect(agreement).to be_valid
    end

    it 'requires agreed_at' do
      agreement = build(:compliance_agreement, agreed_at: nil)
      expect(agreement).not_to be_valid
      expect(agreement.errors[:agreed_at]).to be_present
    end

    it 'requires revision' do
      agreement = build(:compliance_agreement, revision: nil)
      expect(agreement).not_to be_valid
      expect(agreement.errors[:revision]).to be_present
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      user = create(:user)
      agreement = create(:compliance_agreement, user: user)
      expect(agreement.user).to eq(user)
    end

    it 'belongs to a requirement' do
      requirement = create(:compliance_requirement)
      agreement = create(:compliance_agreement, requirement: requirement)
      expect(agreement.requirement).to eq(requirement)
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:requirement) { create(:compliance_requirement) }

    describe '.for_user' do
      it 'returns agreements for the specified user' do
        agreement = create(:compliance_agreement, user: user)
        other_agreement = create(:compliance_agreement, user: other_user)

        expect(described_class.for_user(user)).to include(agreement)
        expect(described_class.for_user(user)).not_to include(other_agreement)
      end
    end

    describe '.for_requirement' do
      it 'returns agreements for the specified requirement' do
        other_requirement = create(:compliance_requirement)
        agreement = create(:compliance_agreement, requirement: requirement)
        other_agreement = create(:compliance_agreement, requirement: other_requirement)

        expect(described_class.for_requirement(requirement)).to include(agreement)
        expect(described_class.for_requirement(requirement)).not_to include(other_agreement)
      end
    end

    describe '.not_expired' do
      it 'returns agreements without expiration' do
        agreement = create(:compliance_agreement, expires_at: nil)
        expect(described_class.not_expired).to include(agreement)
      end

      it 'returns agreements with future expiration' do
        agreement = create(:compliance_agreement, expires_at: 1.day.from_now)
        expect(described_class.not_expired).to include(agreement)
      end

      it 'excludes expired agreements' do
        agreement = create(:compliance_agreement, :expired)
        expect(described_class.not_expired).not_to include(agreement)
      end
    end

    describe '.expired' do
      it 'returns only expired agreements' do
        expired = create(:compliance_agreement, :expired)
        current = create(:compliance_agreement, expires_at: nil)
        future = create(:compliance_agreement, expires_at: 1.day.from_now)

        expect(described_class.expired).to include(expired)
        expect(described_class.expired).not_to include(current)
        expect(described_class.expired).not_to include(future)
      end
    end
  end

  describe '#expired?' do
    it 'returns false when expires_at is nil' do
      agreement = build(:compliance_agreement, expires_at: nil)
      expect(agreement.expired?).to be false
    end

    it 'returns false when expires_at is in the future' do
      agreement = build(:compliance_agreement, expires_at: 1.day.from_now)
      expect(agreement.expired?).to be false
    end

    it 'returns true when expires_at is in the past' do
      agreement = build(:compliance_agreement, expires_at: 1.day.ago)
      expect(agreement.expired?).to be true
    end

    it 'returns true when expires_at is exactly now' do
      freeze_time do
        agreement = build(:compliance_agreement, expires_at: Time.current)
        expect(agreement.expired?).to be true
      end
    end
  end

  describe 'integration with User model' do
    let(:user) { create(:user) }
    let(:requirement) { create(:compliance_requirement) }

    it 'allows access through user.compliance_agreements' do
      agreement = create(:compliance_agreement, user: user, requirement: requirement)
      expect(user.compliance_agreements).to include(agreement)
    end

    it 'allows user.pending_compliance_requirements to work correctly' do
      # No agreement yet
      expect(user.pending_compliance_requirements).to include(requirement)

      # After agreement
      create(:compliance_agreement, user: user, requirement: requirement, revision: requirement.revision)
      expect(user.pending_compliance_requirements).not_to include(requirement)
    end
  end
end
