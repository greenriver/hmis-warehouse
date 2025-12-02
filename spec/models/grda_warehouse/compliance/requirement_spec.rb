###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Compliance::Requirement, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      requirement = build(:compliance_requirement)
      expect(requirement).to be_valid
    end

    it 'requires a name' do
      requirement = build(:compliance_requirement, name: nil)
      expect(requirement).not_to be_valid
      expect(requirement.errors[:name]).to be_present
    end

    it 'requires a content_page' do
      requirement = build(:compliance_requirement, content_page: nil)
      expect(requirement).not_to be_valid
    end

    it 'requires revision to be a positive integer' do
      requirement = build(:compliance_requirement, revision: 0)
      expect(requirement).not_to be_valid

      requirement.revision = -1
      expect(requirement).not_to be_valid

      requirement.revision = 1
      expect(requirement).to be_valid
    end

    it 'allows nil expires_after_days' do
      requirement = build(:compliance_requirement, expires_after_days: nil)
      expect(requirement).to be_valid
    end

    it 'requires expires_after_days to be positive when present' do
      requirement = build(:compliance_requirement, expires_after_days: 0)
      expect(requirement).not_to be_valid

      requirement.expires_after_days = 365
      expect(requirement).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a content_page' do
      content_page = create(:content_page)
      requirement = create(:compliance_requirement, content_page: content_page)
      expect(requirement.content_page).to eq(content_page)
    end

    it 'has many agreements' do
      requirement = create(:compliance_requirement)
      user = create(:user)
      agreement = create(:compliance_agreement, requirement: requirement, user: user)
      expect(requirement.agreements).to include(agreement)
    end

    it 'prevents deletion when agreements exist' do
      requirement = create(:compliance_requirement)
      create(:compliance_agreement, requirement: requirement)
      expect { requirement.destroy }.not_to change(described_class, :count)
      expect(requirement.errors[:base]).to be_present
    end
  end

  describe 'scopes' do
    let!(:active_requirement) { create(:compliance_requirement, active: true, position: 1) }
    let!(:inactive_requirement) { create(:compliance_requirement, active: false, position: 0) }

    describe '.active' do
      it 'returns only active requirements' do
        expect(described_class.active).to include(active_requirement)
        expect(described_class.active).not_to include(inactive_requirement)
      end
    end

    describe '.ordered' do
      it 'orders by position then id' do
        expect(described_class.ordered.first).to eq(inactive_requirement)
        expect(described_class.ordered.last).to eq(active_requirement)
      end
    end
  end

  describe '.pending_for_user' do
    let(:user) { create(:user) }
    let(:requirement) { create(:compliance_requirement, revision: 1) }

    context 'when user has no agreements' do
      it 'returns all active requirements' do
        expect(described_class.pending_for_user(user)).to include(requirement)
      end
    end

    context 'when user has a current agreement' do
      before do
        create(:compliance_agreement, user: user, requirement: requirement, revision: 1)
      end

      it 'does not return the requirement' do
        expect(described_class.pending_for_user(user)).not_to include(requirement)
      end
    end

    context 'when user has an outdated agreement (lower revision)' do
      before do
        create(:compliance_agreement, user: user, requirement: requirement, revision: 1)
        requirement.update!(revision: 2)
      end

      it 'returns the requirement' do
        expect(described_class.pending_for_user(user)).to include(requirement)
      end
    end

    context 'when user has an expired agreement' do
      before do
        create(:compliance_agreement, user: user, requirement: requirement, revision: 1, expires_at: 1.day.ago)
      end

      it 'returns the requirement' do
        expect(described_class.pending_for_user(user)).to include(requirement)
      end
    end

    context 'when requirement is inactive' do
      let(:inactive_requirement) { create(:compliance_requirement, :inactive) }

      it 'does not return inactive requirements' do
        expect(described_class.pending_for_user(user)).not_to include(inactive_requirement)
      end
    end
  end

  describe 'soft delete' do
    it 'supports soft deletion via acts_as_paranoid' do
      requirement = create(:compliance_requirement)
      requirement.destroy
      expect(described_class.with_deleted.find(requirement.id)).to be_present
      expect(described_class.find_by(id: requirement.id)).to be_nil
    end
  end
end
