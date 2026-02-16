# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolUnitGroupAssignment, type: :model do
  let!(:unit_group) { create(:hmis_unit_group) }
  let!(:candidate_pool) { create(:hmis_ce_match_candidate_pool) }
  let!(:candidate_pool_2) { create(:hmis_ce_match_candidate_pool) }

  describe 'database constraints' do
    it 'does not allow ended_at before started_at' do
      assignment = build(:hmis_ce_match_candidate_pool_unit_group_assignment, unit_group: unit_group, candidate_pool: candidate_pool, started_at: 1.week.ago, ended_at: 2.weeks.ago)
      expect do
        assignment.save!
      end.to raise_error(ActiveRecord::StatementInvalid, /range lower bound must be less than or equal to range upper bound/).
        and not_change(Hmis::Ce::Match::CandidatePoolUnitGroupAssignment, :count).from(0)
    end

    context 'when there is an existing active assignment for a unit group' do
      let!(:assignment) { create(:hmis_ce_match_candidate_pool_unit_group_assignment, unit_group: unit_group, candidate_pool: candidate_pool, started_at: 2.weeks.ago, ended_at: nil) }

      it 'does not allow creating another active assignment with a later start date' do
        assignment2 = build(:hmis_ce_match_candidate_pool_unit_group_assignment, unit_group: unit_group, candidate_pool: candidate_pool_2, started_at: 1.week.ago, ended_at: nil)
        expect do
          assignment2.save!
        end.to raise_error(ActiveRecord::StatementInvalid, /violates exclusion constraint/).
          and not_change(Hmis::Ce::Match::CandidatePoolUnitGroupAssignment, :count).from(1)
      end

      it 'does not allow creating an overlapping assignment with an earlier start date' do
        assignment2 = build(:hmis_ce_match_candidate_pool_unit_group_assignment, unit_group: unit_group, candidate_pool: candidate_pool_2, started_at: 3.weeks.ago, ended_at: 1.week.ago)
        expect do
          assignment2.save!
        end.to raise_error(ActiveRecord::StatementInvalid, /violates exclusion constraint/).
          and not_change(Hmis::Ce::Match::CandidatePoolUnitGroupAssignment, :count).from(1)
      end

      it 'allows creating a non-overlapping assignment' do
        assignment2 = build(:hmis_ce_match_candidate_pool_unit_group_assignment, unit_group: unit_group, candidate_pool: candidate_pool_2, started_at: 4.weeks.ago, ended_at: 3.weeks.ago)
        expect do
          assignment2.save!
        end.to change(Hmis::Ce::Match::CandidatePoolUnitGroupAssignment, :count).from(1).to(2)
      end

      it 'allows creating an assignment for a different unit group' do
        assignment2 = build(:hmis_ce_match_candidate_pool_unit_group_assignment, started_at: 1.week.ago)
        expect do
          assignment2.save!
        end.to change(Hmis::Ce::Match::CandidatePoolUnitGroupAssignment, :count).from(1).to(2)
      end
    end
  end
end
