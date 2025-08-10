# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilder do
  let!(:organization) { create :hmis_hud_organization }
  let!(:project) { create :hmis_hud_project, organization: organization }
  let!(:opportunity) { create(:hmis_ce_opportunity, project: project, data_source: project.data_source) }
  let(:builder) { described_class.new(Hmis::Ce::Opportunity.active) }

  describe '#perform' do
    context 'with active opportunities' do
      let!(:rule1) { create(:hmis_ce_eligibility_requirement, owner: organization) }
      let!(:rule2) { create(:hmis_ce_priority_scheme, owner: organization) }

      before do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      end

      it 'creates pools based on unique rule combinations' do
        expect { builder.perform }.to change(Hmis::Ce::Match::CandidatePool, :count).by(1)
      end

      it 'assigns opportunities to appropriate pools' do
        builder.perform
        pool = Hmis::Ce::Match::CandidatePool.last
        expect(opportunity.reload.candidate_pool).to eq(pool)
      end

      it 'captures assignment rules for historical reference' do
        builder.perform
        reloaded_opportunity = opportunity.reload

        expect(reloaded_opportunity.assignment_rules).to be_present
        expect(reloaded_opportunity.assignment_rules).to be_an(Array)

        # Should contain rule attributes for both eligibility and priority rules
        rule_ids = reloaded_opportunity.assignment_rules.map { |attrs| attrs['id'] }
        expect(rule_ids).to contain_exactly(rule1.id, rule2.id)

        # Should preserve rule attributes including expressions and types
        rule_attrs = reloaded_opportunity.assignment_rules.index_by { |attrs| attrs['id'] }
        expect(rule_attrs[rule1.id]['rule_type']).to eq('eligibility_requirement')
        expect(rule_attrs[rule2.id]['rule_type']).to eq('priority_scheme')
        expect(rule_attrs[rule1.id]['expression']).to eq(rule1.expression)
        expect(rule_attrs[rule2.id]['expression']).to eq(rule2.expression)
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
      let!(:opportunity_with_pool) { create(:hmis_ce_opportunity, candidate_pool: active_pool) }

      before do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:days_to_retain_orphan_candidate_pools).and_return(expiration_days)
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      end

      it 'deletes old orphaned pools but not new or active ones' do
        expect { builder.send(:cleanup_orphan_pools) }.to change(Hmis::Ce::Match::CandidatePool, :count).by(-1)
        expect(Hmis::Ce::Match::CandidatePool.exists?(old_orphaned_pool.id)).to be_falsey
        expect(Hmis::Ce::Match::CandidatePool.exists?(new_orphaned_pool.id)).to be_truthy
        expect(Hmis::Ce::Match::CandidatePool.exists?(active_pool.id)).to be_truthy
      end
    end

    context 'with stale tracking' do
      let!(:tracked_opportunity) do
        create(:hmis_ce_opportunity,
               project: project,
               data_source: project.data_source,
               candidate_pool: nil,
               stale: false)
      end
      let!(:rule1) { create(:hmis_ce_eligibility_requirement, owner: organization) }
      let!(:rule2) { create(:hmis_ce_priority_scheme, owner: organization) }

      before do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      end

      context 'when rules change requiring different pool' do
        before do
          Hmis::Ce::Match::Rule.destroy_all
        end
        let!(:org_rule) do
          create(:hmis_ce_eligibility_requirement,
                 owner: organization,
                 expression: 'current_age >= 25',
                 applicability_config: {})
        end
        let!(:project_specific_rule) do
          create(:hmis_ce_eligibility_requirement,
                 owner: project,
                 expression: 'current_age >= 18',
                 applicability_config: {})
        end

        it 'marks opportunity as stale but keeps it in original pool' do
          builder = described_class.new(Hmis::Ce::Opportunity.where(id: tracked_opportunity.id))

          # First run establishes the pool assignment with initial rules
          builder.perform
          first_pool = tracked_opportunity.reload.candidate_pool
          expect(tracked_opportunity.stale).to be_falsey

          # Capture the initial pool expressions that were applied
          initial_priority = first_pool.priority_expression
          initial_requirement = first_pool.requirement_expression

          # Add a new rule that will create a different rule combination
          create(:hmis_ce_priority_scheme,
                 owner: project,
                 expression: 'days_homeless * 2',
                 applicability_config: {})

          # Second run should detect the rule change, must use a new builder to pick up new rule
          described_class.new(Hmis::Ce::Opportunity.where(id: tracked_opportunity.id)).perform
          tracked_opportunity.reload

          # The opportunity should be flagged as stale because the rules changed
          # but it should remain in the original pool
          expect(tracked_opportunity.candidate_pool).to eq(first_pool) # Stays in original pool
          expect(tracked_opportunity.stale).to be_truthy # But flagged as stale

          # Verify that a new pool would have been created with different expressions
          # if this was a new opportunity
          resolver = Hmis::Ce::Match::UnitGroupRuleResolver.new
          unit_group = tracked_opportunity.reload.unit&.unit_group
          new_key = resolver.key_for_unit_group(unit_group: unit_group, project: project, organization: organization)
          expected_new_priority = new_key.first
          expected_new_requirement = new_key.second

          # The new key should be different from the original pool
          expect([expected_new_priority, expected_new_requirement]).not_to eq([initial_priority, initial_requirement])
        end
      end

      context 'when clearing stale flags' do
        it 'clears stale flag when opportunity is already in correct pool' do
          # First create a pool by processing the opportunity
          temp_opportunity = create(:hmis_ce_opportunity, project: project, data_source: project.data_source)
          temp_builder = described_class.new(Hmis::Ce::Opportunity.where(id: temp_opportunity.id))
          temp_builder.perform
          correct_pool = temp_opportunity.reload.candidate_pool

          # Create stale opportunity in the correct pool
          stale_opportunity = create(:hmis_ce_opportunity,
                                     project: project,
                                     data_source: project.data_source,
                                     candidate_pool: correct_pool,
                                     stale: true)

          builder = described_class.new(Hmis::Ce::Opportunity.where(id: stale_opportunity.id))
          builder.perform

          expect(stale_opportunity.reload.stale).to be_falsey
          expect(stale_opportunity.candidate_pool).to eq(correct_pool)
        end

        it 'processes multiple opportunities with different states efficiently' do
          # Create opportunities with different initial states
          new_opportunity = create(:hmis_ce_opportunity,
                                   project: project,
                                   data_source: project.data_source,
                                   candidate_pool: nil)

          # Create a pool first to have a "correct" pool reference
          temp_opportunity = create(:hmis_ce_opportunity, project: project, data_source: project.data_source)
          temp_builder = described_class.new(Hmis::Ce::Opportunity.where(id: temp_opportunity.id))
          temp_builder.perform
          existing_pool = temp_opportunity.reload.candidate_pool

          stale_opportunity = create(:hmis_ce_opportunity,
                                     project: project,
                                     data_source: project.data_source,
                                     candidate_pool: existing_pool,
                                     stale: true)

          # Process both in a single batch operation
          builder = described_class.new(Hmis::Ce::Opportunity.where(id: [new_opportunity.id, stale_opportunity.id]))

          expect { builder.perform }.to change {
            [new_opportunity.reload.candidate_pool.present?, stale_opportunity.reload.stale]
          }.from([false, true]).to([true, false])
        end
      end
    end
  end

  describe 'locking behavior' do
    it 'acquires an advisory lock' do
      expect(GrdaWarehouseBase).to receive(:with_advisory_lock).
        with('CandidatePoolBuilder', timeout_seconds: 30).
        and_call_original

      builder.perform
    end

    it 'wraps operations in a transaction' do
      expect(Hmis::Ce::Match::CandidatePool).to receive(:transaction)
      builder.perform
    end
  end

  describe 'when there are many rules' do
    before do
      50.times { create(:hmis_ce_eligibility_requirement, owner: project) }
      50.times { create(:hmis_ce_eligibility_requirement, owner: organization) }
    end

    it 'queries the db a reasonable amount' do
      expect do
        builder.perform
      end.to make_database_queries(count: 20..25)
    end
  end
end
