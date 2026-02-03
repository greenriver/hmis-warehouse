# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilder do
  let!(:organization) { create(:hmis_hud_organization) }
  let!(:project) { create(:hmis_hud_project, organization: organization) }
  let!(:ce_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: project) }
  let!(:other_project) { create(:hmis_hud_project, organization: organization) } # project without waitlists enabled

  before do
    allow_any_instance_of(Hmis::Ce::Match::Rule).to receive(:rebuild_candidate_pools) # prevent automatic rebuilds
    allow_any_instance_of(Hmis::UnitGroup).to receive(:rebuild_candidate_pool) # prevent automatic rebuilds
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
  end

  describe '#call' do
    context 'with unit groups' do
      let!(:unit_group_1) { create(:hmis_unit_group, project: project) }
      let!(:unit_group_2) { create(:hmis_unit_group, project: project) }
      let!(:unit_group_no_rules) { create(:hmis_unit_group, project: project) }
      let!(:unit_group_waitlists_not_enabled) { create(:hmis_unit_group, project: other_project) }

      before do
        # These rules create two distinct keys, resulting in two pools
        create(:hmis_ce_eligibility_requirement, owner: unit_group_1, expression: 'a = 1')
        create(:hmis_ce_priority_scheme, owner: unit_group_1, expression: 'score_1')

        create(:hmis_ce_eligibility_requirement, owner: unit_group_2, expression: 'b = 2')
        create(:hmis_ce_priority_scheme, owner: unit_group_2, expression: 'score_2')
      end

      it 'creates pools for unique rule combinations and marks them dirty' do
        expect { described_class.call }.to change(Hmis::Ce::Match::CandidatePool, :count).by(2)
        # Both newly created pools should be marked dirty
        expect(Hmis::Ce::ChangeMarker.dirty.pools.count).to eq(2)
      end

      it 'assigns unit groups to the appropriate pools' do
        described_class.call
        pool1 = Hmis::Ce::Match::CandidatePool.find_by(priority_expression: '{score_1}')
        pool2 = Hmis::Ce::Match::CandidatePool.find_by(requirement_expression: 'b = 2')

        expect(unit_group_1.reload.candidate_pool).to eq(pool1)
        expect(unit_group_2.reload.candidate_pool).to eq(pool2)
      end

      it 'leaves candidate_pool_id nil for unit groups with no rules' do
        described_class.call
        expect(unit_group_no_rules.reload.candidate_pool_id).to be_nil
      end

      it 'leaves candidate_pool_id nil for unit groups without waitlists enabled' do
        described_class.call
        expect(unit_group_waitlists_not_enabled.reload.candidate_pool_id).to be_nil
      end

      it 'can be scoped to specific unit groups' do
        expect { described_class.call(unit_group_ids: [unit_group_1.id]) }.
          to change(Hmis::Ce::Match::CandidatePool, :count).by(1)
        expect(unit_group_1.reload.candidate_pool).to be_present
        # unit_group_2 should not have been processed/associated
        expect(unit_group_2.reload.candidate_pool).to be_nil
      end
    end

    context 'when unit group rules change' do
      let!(:unit_group) { create(:hmis_unit_group, project: project) }

      it 'updates the unit group association to the new pool' do
        create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'a = 1')
        create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score_a')
        described_class.call
        first_pool_id = unit_group.reload.candidate_pool_id
        expect(first_pool_id).to be_present

        # Add a rule, which changes the key and should result in a new pool
        create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'b = 1')
        described_class.call
        second_pool_id = unit_group.reload.candidate_pool_id

        expect(second_pool_id).to be_present
        expect(second_pool_id).not_to eq(first_pool_id)
      end
    end

    context 'with opportunity backfilling' do
      let!(:unit) { create(:hmis_unit, project: project) }
      let!(:opportunity_without_pool) { create(:hmis_ce_opportunity, unit: unit, candidate_pool: nil) }
      let(:unit_group) { unit.unit_group }

      it 'backfills the pool and rules for opportunities missing them' do
        [
          create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'a = 1'),
          create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score_a'),
        ]

        described_class.call
        opportunity_without_pool.reload

        expect(opportunity_without_pool.candidate_pool_id).to eq(unit_group.reload.candidate_pool_id)

        # The `assignment_rules` attribute stores a serialized snapshot of the rules.
        # We need to compare the essential parts of these stored rules.
        actual_rules = opportunity_without_pool.assignment_rules.map { |r| r.slice('rule_type', 'expression') }
        expected_rules = [{ 'rule_type' => 'eligibility_requirement', 'expression' => 'a = 1' }, { 'rule_type' => 'priority_scheme', 'expression' => 'score_a' }]

        expect(actual_rules).to contain_exactly(*expected_rules)
      end
    end

    context 'with stale tracking' do
      let!(:unit) { create(:hmis_unit, project: project) }
      let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit) }
      let(:unit_group) { unit.unit_group }

      it 'marks opportunity as stale when unit group pool changes and marks as clean when unit group pool reverts' do
        rule = create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'a = 1')
        create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score_a')

        described_class.call
        expect(opportunity.reload.candidate_pool).to be_present
        expect(opportunity.reload.stale).to be_falsey

        # Make the opportunity stale
        rule.update!(expression: 'a = 2')
        expect { described_class.call }.to change { opportunity.reload.stale }.from(false).to(true)

        # reverting the unit group to its original pool
        rule.update!(expression: 'a = 1')
        expect { described_class.call }.to change { opportunity.reload.stale }.from(true).to(false)
      end
    end

    context 'with closed projects' do
      let!(:closed_project) { create(:hmis_hud_project, organization: organization, operating_end_date: 1.day.ago) }
      let!(:ce_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: closed_project) }
      let!(:unit) { create(:hmis_unit, project: closed_project) }
      let!(:opportunity) { create(:hmis_ce_opportunity, candidate_pool: nil, unit: unit) }
      let(:unit_group) { unit.unit_group }

      before do
        # Add rules to the closed project's unit group
        create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'closed_project_eligible = 1')
        create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'closed_project_score')
      end

      it 'does not create candidate pools for closed projects' do
        expect { described_class.call }.not_to change(Hmis::Ce::Match::CandidatePool, :count)
      end

      it 'does not associate unit groups from closed projects with candidate pools' do
        described_class.call
        expect(unit_group.reload.candidate_pool_id).to be_nil
      end

      it 'does not backfill opportunities from closed projects' do
        described_class.call
        opportunity.reload
        expect(opportunity.candidate_pool_id).to be_nil
      end

      it 'excludes closed projects even when scoped to specific unit groups' do
        expect { described_class.call(unit_group_ids: [unit_group.id]) }.
          not_to change(Hmis::Ce::Match::CandidatePool, :count)
        expect(unit_group.reload.candidate_pool_id).to be_nil
      end

      it 'only processes open projects when both open and closed projects exist' do
        # Create unit group in open project for comparison
        open_unit_group = create(:hmis_unit_group, project: project)
        create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: project)
        create(:hmis_ce_eligibility_requirement, owner: open_unit_group, expression: 'open_project_eligible = 1')
        create(:hmis_ce_priority_scheme, owner: open_unit_group, expression: 'open_project_score')

        expect { described_class.call }.to change(Hmis::Ce::Match::CandidatePool, :count).from(0).to(1)

        # Only the open project's unit group should be associated with a pool
        expect(open_unit_group.reload.candidate_pool).to be_present
        expect(unit_group.reload.candidate_pool_id).to be_nil
      end
    end
  end

  describe 'locking behavior' do
    it 'defers locking to callers (no direct advisory lock held by builder)' do
      expect(GrdaWarehouseBase).not_to receive(:with_advisory_lock)
      described_class.call
    end

    it 'does not open a top-level transaction (callers own transactional semantics)' do
      expect(Hmis::Ce::Match::CandidatePool).not_to receive(:transaction)
      described_class.call
    end
  end

  describe 'rule specificity and ranking' do
    let!(:data_source) { project.data_source }
    let!(:unit_group_1) { create(:hmis_unit_group, project: project) }
    # we must have at least one eligibility rule to generate pools
    let!(:project_eligibility) { create(:hmis_ce_eligibility_requirement, owner: project, expression: 'project_eligible = 1') }

    before do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    end

    context 'when priority schemes exist at different specificity levels' do
      let!(:data_source_rule) { create(:hmis_ce_priority_scheme, owner: data_source, expression: 'data_source_score', priority_rank: 1) }
      let!(:organization_rule) { create(:hmis_ce_priority_scheme, owner: organization, expression: 'org_score', priority_rank: 1) }
      let!(:project_rule) { create(:hmis_ce_priority_scheme, owner: project, expression: 'project_score', priority_rank: 1) }

      it 'uses only the most specific rule (project level)' do
        described_class.call
        pool = Hmis::Ce::Match::CandidatePool.last
        expect(pool.priority_expression).to eq('{project_score}')
      end
    end

    context 'when multiple priority schemes exist at the same specificity level' do
      let!(:project_rule_1) { create(:hmis_ce_priority_scheme, owner: project, expression: 'first_score', priority_rank: 2) }
      let!(:project_rule_2) { create(:hmis_ce_priority_scheme, owner: project, expression: 'second_score', priority_rank: 1) }
      let!(:project_rule_3) { create(:hmis_ce_priority_scheme, owner: project, expression: 'third_score', priority_rank: 3) }

      it 'uses all rules at that level, ordered by rank' do
        described_class.call
        pool = Hmis::Ce::Match::CandidatePool.last
        expect(pool.priority_expression).to eq('{second_score, first_score, third_score}')
      end
    end

    context 'when only organization-level rules exist' do
      let!(:org_rule_1) { create(:hmis_ce_priority_scheme, owner: organization, expression: 'org_first', priority_rank: 2) }
      let!(:org_rule_2) { create(:hmis_ce_priority_scheme, owner: organization, expression: 'org_second', priority_rank: 1) }
      let!(:data_source_rule) { create(:hmis_ce_priority_scheme, owner: data_source, expression: 'data_source_score', priority_rank: 1) }

      it 'uses organization-level rules in rank order, ignoring data source rules' do
        described_class.call
        pool = Hmis::Ce::Match::CandidatePool.last
        expect(pool.priority_expression).to eq('{org_second, org_first}')
      end
    end

    context 'when eligibility requirements exist at different specificity levels' do
      let!(:data_source_eligibility) { create(:hmis_ce_eligibility_requirement, owner: data_source, expression: 'data_source_eligible = 1') }
      let!(:organization_eligibility) { create(:hmis_ce_eligibility_requirement, owner: organization, expression: 'org_eligible = 1') }
      let!(:project_eligibility) { create(:hmis_ce_eligibility_requirement, owner: project, expression: 'project_eligible = 1') }
      let!(:project_priority) { create(:hmis_ce_priority_scheme, owner: project, expression: 'project_score', priority_rank: 1) }

      it 'uses all eligibility requirements regardless of specificity' do
        described_class.call
        pool = Hmis::Ce::Match::CandidatePool.last
        # Order may vary, so check that all requirements are included
        requirements = pool.requirement_expression.split(' AND ')
        expect(requirements).to contain_exactly('data_source_eligible = 1', 'org_eligible = 1', 'project_eligible = 1')
      end
    end

    context 'mixed scenario with priority schemes and eligibility requirements' do
      let!(:data_source_priority) { create(:hmis_ce_priority_scheme, owner: data_source, expression: 'ds_priority', priority_rank: 1) }
      let!(:project_priority) { create(:hmis_ce_priority_scheme, owner: project, expression: 'proj_priority', priority_rank: 1) }
      let!(:data_source_eligibility) { create(:hmis_ce_eligibility_requirement, owner: data_source, expression: 'ds_eligible = 1') }
      let!(:project_eligibility) { create(:hmis_ce_eligibility_requirement, owner: project, expression: 'proj_eligible = 1') }

      it 'uses most specific priority scheme but all eligibility requirements' do
        described_class.call
        pool = Hmis::Ce::Match::CandidatePool.last

        expect(pool.priority_expression).to eq('{proj_priority}')

        requirements = pool.requirement_expression.split(' AND ')
        expect(requirements).to contain_exactly('ds_eligible = 1', 'proj_eligible = 1')
      end
    end
  end
end
