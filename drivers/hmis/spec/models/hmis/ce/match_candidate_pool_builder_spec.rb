# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilder do
  let(:builder) { described_class.new }
  let!(:opportunity) { create(:hmis_ce_opportunity) }
  let(:project) { opportunity.project }
  let(:organization) { project.organization }

  describe '#perform' do
    context 'with active opportunities' do
      let!(:rule1) { create(:hmis_ce_eligibility_requirement, owner: organization) }
      let!(:rule2) { create(:hmis_ce_priority_scheme, owner: organization) }

      before do
        allow_any_instance_of(Hmis::Ce::Match::Rule).to receive(:applies_to_opportunity?).and_return(true)
      end

      it 'creates pools based on unique rule combinations' do
        expect { builder.perform }.to change(Hmis::Ce::Match::CandidatePool, :count).by(1)
      end

      it 'assigns opportunities to appropriate pools' do
        builder.perform
        pool = Hmis::Ce::Match::CandidatePool.last
        expect(opportunity.reload.candidate_pool).to eq(pool)
      end

      it 'updates existing pools configuration timestamp' do
        pool = create(:hmis_ce_match_candidate_pool, requirement_expression: 'current_age >= 18', priority_expression: 'days_homeless')

        expect { builder.perform }.to(change { pool.reload.configuration_updated_at })
      end

      it 'cleans up unused pools after expiration period' do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:days_to_retain_orphan_candidate_pools).and_return(90)
        old_pool = create(:hmis_ce_match_candidate_pool, configuration_updated_at: 7.months.ago)

        expect { builder.perform }.to change(Hmis::Ce::Match::CandidatePool, :count).by(0)
        expect(Hmis::Ce::Match::CandidatePool.exists?(old_pool.id)).to be false
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
      end.to make_database_queries(count: 10..20)
    end
  end
end
