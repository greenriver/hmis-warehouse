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
        allow_any_instance_of(Hmis::Ce::Match::Rule).to receive(:applies_to_entity?).and_return(true)
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

    context 'when passed specific opportunities' do
      let!(:opportunity2) { create(:hmis_ce_opportunity, project: project, data_source: project.data_source) }
      let(:builder) { described_class.new(Hmis::Ce::Opportunity.where(id: [opportunity2.id])) }

      it 'does not impact the non-included opportunity' do
        expect do
          builder.perform
          opportunity.reload
          opportunity2.reload
        end.to change(opportunity2, :candidate_pool).from(nil).
          and not_change(opportunity, :candidate_pool).from(nil)
      end
    end

    context 'with stale_rules tracking' do
      let!(:tracked_opportunity) do
        create(:hmis_ce_opportunity,
               project: project,
               data_source: project.data_source,
               candidate_pool: nil,
               stale_rules: false)
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
          expect(tracked_opportunity.stale_rules).to be_falsey

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
          expect(tracked_opportunity.stale_rules).to be_truthy # But flagged as stale

          # Verify that a new pool would have been created with different expressions
          # if this was a new opportunity
          resolver = Hmis::Ce::Match::CandidatePoolResolver.new
          scope = Hmis::Ce::Opportunity.where(id: tracked_opportunity.id)
          new_key = resolver.opportunities_by_key(opportunity_scope: scope).keys.first
          expected_new_priority = new_key.first
          expected_new_requirement = new_key.second

          # The new key should be different from the original pool
          expect([expected_new_priority, expected_new_requirement]).not_to eq([initial_priority, initial_requirement])
        end
      end

      context 'when opportunity is already in correct pool' do
        before do
          allow_any_instance_of(Hmis::Ce::Match::Rule).to receive(:applies_to_entity?).and_return(true)

          # First assign opportunity to a pool and mark as stale
          builder.perform
          tracked_opportunity.reload
          tracked_opportunity.update_column(:stale_rules, true)
        end

        it 'clears stale_rules flag when rules are stable' do
          expect(tracked_opportunity.reload.stale_rules).to be_truthy

          builder = described_class.new(Hmis::Ce::Opportunity.where(id: tracked_opportunity.id))
          builder.perform

          expect(tracked_opportunity.reload.stale_rules).to be_falsey
        end
      end

      context 'with mixed scenarios' do
        let!(:new_opportunity) { create(:hmis_ce_opportunity, project: project, data_source: project.data_source) }

        # Use a separate builder run to create the "correct" pool for testing
        let!(:correct_pool) do
          # Create the pool that the new_opportunity should be assigned to
          temp_builder = described_class.new(Hmis::Ce::Opportunity.where(id: new_opportunity.id))
          temp_builder.perform
          new_opportunity.reload.candidate_pool
        end

        let!(:stale_opportunity) do
          create(:hmis_ce_opportunity,
                 project: project,
                 data_source: project.data_source,
                 candidate_pool: correct_pool,
                 stale_rules: true)
        end

        before do
          # Reset the new_opportunity to unassigned state for the main test
          new_opportunity.update_column(:candidate_pool_id, nil)
          new_opportunity.update_column(:stale_rules, false)
        end

        it 'handles new assignments and stale flag clearing in single operation' do
          builder = described_class.new(Hmis::Ce::Opportunity.where(id: [new_opportunity.id, stale_opportunity.id]))
          builder.perform

          new_opportunity.reload
          stale_opportunity.reload

          # New opportunity gets assigned and not flagged as stale
          expect(new_opportunity.candidate_pool).to be_present
          expect(new_opportunity.stale_rules).to be_falsey

          # Stale opportunity gets unstaled if in correct pool
          expect(stale_opportunity.candidate_pool).to eq(correct_pool)
          expect(stale_opportunity.stale_rules).to be_falsey
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
      50.times { create(:hmis_ce_eligibility_requirement, owner: opportunity) }
      50.times { create(:hmis_ce_eligibility_requirement, owner: project) }
      50.times { create(:hmis_ce_eligibility_requirement, owner: organization) }
    end

    it 'queries the db a reasonable amount' do
      expect do
        builder.perform
      end.to make_database_queries(count: 20..25)
    end
  end

  describe 'candidate pool stability validation' do
    let!(:pool1) { create(:hmis_ce_match_candidate_pool) }
    let!(:pool2) { create(:hmis_ce_match_candidate_pool) }
    let!(:opportunity_with_pool) do
      create(:hmis_ce_opportunity,
             project: project,
             data_source: project.data_source,
             candidate_pool: pool1)
    end

    it 'prevents changing candidate_pool_id after initial assignment' do
      # Attempt to change the pool
      opportunity_with_pool.candidate_pool = pool2

      expect(opportunity_with_pool).not_to be_valid
      expect(opportunity_with_pool.errors[:candidate_pool_id]).to include('cannot be changed after initial assignment')
    end

    it 'allows updating other attributes when candidate_pool stays same' do
      opportunity_with_pool.name = 'Updated Name'

      expect(opportunity_with_pool).to be_valid
    end

    it 'allows setting candidate_pool_id on new opportunities' do
      new_opportunity = build(:hmis_ce_opportunity,
                              project: project,
                              data_source: project.data_source,
                              candidate_pool: pool1)

      expect(new_opportunity).to be_valid
    end

    it 'allows changing from nil to a pool' do
      opportunity_without_pool = create(:hmis_ce_opportunity,
                                        project: project,
                                        data_source: project.data_source,
                                        candidate_pool: nil)

      opportunity_without_pool.candidate_pool = pool1
      expect(opportunity_without_pool).to be_valid
    end
  end
end
