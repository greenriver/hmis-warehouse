# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolUnitGroupAssignment, type: :model do
  let!(:unit_group) { create(:hmis_unit_group) }
  let!(:candidate_pool) { create(:hmis_ce_match_candidate_pool) }
  let!(:candidate_pool_2) { create(:hmis_ce_match_candidate_pool) }

  describe 'validations' do
    it 'validates that ended_at is after started_at' do
      assignment = described_class.new(
        unit_group: unit_group,
        candidate_pool: candidate_pool,
        started_at: 1.day.ago,
        ended_at: 1.day.from_now,
      )
      expect(assignment).to be_valid

      assignment.ended_at = 2.days.ago
      expect(assignment).not_to be_valid
      expect(assignment.errors.full_messages).to include('Ended at must be after started at')
    end

    it 'validates that there is only one active assignment per unit group' do
      assignment = described_class.new(
        unit_group: unit_group,
        candidate_pool: candidate_pool,
        started_at: 1.day.ago,
        ended_at: nil,
      )
      expect(assignment).to be_valid
      assignment.save!

      assignment2 = described_class.new(
        unit_group: unit_group,
        candidate_pool: candidate_pool_2,
        started_at: 1.day.ago,
        ended_at: nil,
      )
      expect(assignment2).not_to be_valid
      expect(assignment2.errors.full_messages).to include('Only one active assignment per unit group is allowed')
    end
  end
end
