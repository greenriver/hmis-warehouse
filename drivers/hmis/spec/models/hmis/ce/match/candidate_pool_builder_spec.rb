# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilder do
  let!(:organization) { create(:hmis_hud_organization) }
  let!(:project) { create(:hmis_hud_project, organization: organization) }
  let(:builder) { described_class.new }

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
  end

  describe '#perform' do
    context 'with unit groups' do
      let!(:unit_group_1) { create(:hmis_unit_group, project: project) }
      let!(:unit_group_2) { create(:hmis_unit_group, project: project) }
      let!(:unit_group_no_rules) { create(:hmis_unit_group, project: project) }

      before do
        # These rules create two distinct keys, resulting in two pools
        create(:hmis_ce_eligibility_requirement, owner: unit_group_1, expression: 'a = 1')
        create(:hmis_ce_priority_scheme, owner: unit_group_1, expression: 'score_1')

        create(:hmis_ce_eligibility_requirement, owner: unit_group_2, expression: 'b = 2')
      end

      it 'creates pools for unique rule combinations and marks them dirty' do
        expect { builder.perform }.to change(Hmis::Ce::Match::CandidatePool, :count).by(2)
        expect(Hmis::Ce::ChangeMarker.dirty.pools.count).to eq(2)
      end

      it 'assigns unit groups to the appropriate pools' do
        builder.perform
        pool1 = Hmis::Ce::Match::CandidatePool.find_by(priority_expression: 'score_1')
        pool2 = Hmis::Ce::Match::CandidatePool.find_by(requirement_expression: 'b = 2')

        expect(unit_group_1.reload.candidate_pool).to eq(pool1)
        expect(unit_group_2.reload.candidate_pool).to eq(pool2)
      end

      it 'leaves candidate_pool_id nil for unit groups with no rules' do
        builder.perform
        expect(unit_group_no_rules.reload.candidate_pool_id).to be_nil
      end

      it 'can be scoped to specific unit groups' do
        # Running only for unit_group_1 should create one pool
        expect { builder.perform(unit_group_ids: [unit_group_1.id]) }.to change(Hmis::Ce::Match::CandidatePool, :count).by(1)
        expect(unit_group_1.reload.candidate_pool).to be_present
        # unit_group_2 should not have been processed
        expect(unit_group_2.reload.candidate_pool).to be_nil
      end
    end

    context 'when unit group rules change' do
      let!(:unit_group) { create(:hmis_unit_group, project: project) }

      it 'updates the unit group association to the new pool' do
        create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'a = 1')
        builder.perform
        first_pool_id = unit_group.reload.candidate_pool_id
        expect(first_pool_id).to be_present

        # Add a rule, which changes the key and should result in a new pool
        create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score_a')
        builder.perform
        second_pool_id = unit_group.reload.candidate_pool_id

        expect(second_pool_id).to be_present
        expect(second_pool_id).not_to eq(first_pool_id)
      end
    end

    context 'with stale tracking' do
      let!(:unit_group) { create(:hmis_unit_group, project: project) }
      let!(:opportunity) { create(:hmis_ce_opportunity, unit: create(:hmis_unit, unit_group: unit_group), stale: false) }

      before do
        # Initial run to assign pool to opportunity and unit group
        create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'a = 1')
        builder.perform
        opportunity.update!(candidate_pool_id: unit_group.reload.candidate_pool_id)
        expect(opportunity.stale).to be_falsey
      end

      it 'marks opportunity as stale when unit group pool changes' do
        # Change the rule for the unit group, which will cause it to be assigned a new pool
        create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score_a')
        expect { builder.perform }.to change { opportunity.reload.stale }.from(false).to(true)
      end

      it 'clears stale flag when unit group pool reverts' do
        # Make the opportunity stale
        rule = create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score_a')
        builder.perform
        expect(opportunity.reload.stale).to be_truthy

        # Remove the rule, reverting the unit group to its original pool
        rule.destroy
        expect { builder.perform }.to change { opportunity.reload.stale }.from(true).to(false)
      end
    end

    context 'with orphaned candidate pools' do
      let(:expiration_days) { 30 }
      let!(:old_orphaned_pool) do
        create(:hmis_ce_match_candidate_pool, updated_at: (expiration_days + 1).days.ago)
      end
      let!(:new_orphaned_pool) do
        create(:hmis_ce_match_candidate_pool, updated_at: (expiration_days - 1).days.ago)
      end
      let!(:active_pool) { create(:hmis_ce_match_candidate_pool, updated_at: (expiration_days + 1).days.ago) }
      let!(:unit_group_with_pool) { create(:hmis_unit_group, candidate_pool: active_pool) }

      before do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:days_to_retain_orphan_candidate_pools).and_return(expiration_days)
      end

      it 'deletes old orphaned pools but not new or active ones' do
        expect { builder.perform }.to change(Hmis::Ce::Match::CandidatePool, :count).by(-1)
        expect(Hmis::Ce::Match::CandidatePool.exists?(old_orphaned_pool.id)).to be_falsey
        expect(Hmis::Ce::Match::CandidatePool.exists?(new_orphaned_pool.id)).to be_truthy
        expect(Hmis::Ce::Match::CandidatePool.exists?(active_pool.id)).to be_truthy
      end
    end
  end

  describe 'locking behavior' do
    it 'acquires an advisory lock' do
      expect(GrdaWarehouseBase).to receive(:with_advisory_lock).
        with('CandidatePoolBuilder', timeout_seconds: 3).
        and_call_original

      builder.perform
    end

    it 'wraps operations in a transaction' do
      expect(Hmis::Ce::Match::CandidatePool).to receive(:transaction)
      builder.perform
    end
  end
end
