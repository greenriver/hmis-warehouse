# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::BuildCandidatePoolsJob, type: :job do
  include ActiveJob::TestHelper

  before do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  context 'when no opportunity_ids are provided' do
    let!(:opportunity_1) { create(:hmis_ce_opportunity) }
    let!(:opportunity_2) { create(:hmis_ce_opportunity) }

    before do
      create(:hmis_ce_eligibility_requirement, owner: opportunity_1.project, expression: 'current_age = 50')
      create(:hmis_ce_eligibility_requirement, owner: opportunity_2.project, expression: 'current_age = 51')
      # build the initial pools
      Hmis::Ce::Match::CandidatePoolBuilder.new(Hmis::Ce::Opportunity.active).perform
    end

    it 'marks all candidate pools as dirty' do
      expect do
        described_class.perform_now
      end.to change { Hmis::Ce::ChangeMarker.dirty.pools.count }.from(0).to(2)

      expect(opportunity_1.reload.candidate_pool.change_marker).to be_dirty
      expect(opportunity_2.reload.candidate_pool.change_marker).to be_dirty
    end
  end

  context 'when there are no active opportunities' do
    let!(:project) { create(:hmis_hud_project) }
    let!(:unit_group) { create(:hmis_unit_group, project: project, candidate_pool: nil) }

    before do
      create(:hmis_ce_eligibility_requirement, owner: project, expression: 'current_age >= 18')
    end

    it 'creates pools for unit groups and marks all pools dirty on full run' do
      expect { described_class.perform_now }.to change(Hmis::Ce::Match::CandidatePool, :count).by(1)

      pool = Hmis::Ce::Match::CandidatePool.last
      expect(unit_group.reload.candidate_pool_id).to eq(pool.id)

      # Full run marks all pools dirty
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool)).to be_dirty
    end
  end

  context 'when specific opportunity_ids are provided' do
    let!(:opportunity) { create(:hmis_ce_opportunity) }

    before do
      create(:hmis_ce_eligibility_requirement, owner: opportunity.project, expression: 'current_age = 60')
      # Initial build to create first pool
      Hmis::Ce::BuildCandidatePoolsJob.perform_now
      # Reset dirtiness
      Hmis::Ce::ChangeMarker.update_all(processed_version: 1, current_version: 1)
    end

    it 'processes all unit groups but marks only newly created pools dirty' do
      # Introduce a different rule on another project’s unit group (no related opportunity)
      other_project = create(:hmis_hud_project)
      other_unit_group = create(:hmis_unit_group, project: other_project, candidate_pool: nil)
      create(:hmis_ce_eligibility_requirement, owner: other_project, expression: 'current_age = 61')

      expect do
        described_class.perform_now(opportunity_ids: [opportunity.id])
      end.to change(Hmis::Ce::Match::CandidatePool, :count).by(1)

      new_pool = other_unit_group.reload.candidate_pool
      expect(new_pool).to be_present

      # Only the newly created pool is marked dirty
      dirty_pool_ids = Hmis::Ce::ChangeMarker.dirty.pools.pluck(:trackable_id)
      expect(dirty_pool_ids).to match_array([new_pool.id])
    end
  end

  context 'when unit group rules change' do
    let!(:project) { create(:hmis_hud_project) }
    let!(:unit_group) { create(:hmis_unit_group, project: project) }

    it 'moves the unit group association to the new pool' do
      create(:hmis_ce_eligibility_requirement, owner: project, expression: 'a = 1')
      described_class.perform_now
      first_pool_id = unit_group.reload.candidate_pool_id

      # Change effective rules; this should target a different pool
      create(:hmis_ce_eligibility_requirement, owner: project, expression: 'b = 2')
      described_class.perform_now
      second_pool_id = unit_group.reload.candidate_pool_id

      expect(second_pool_id).to be_present
      expect(second_pool_id).not_to eq(first_pool_id)
    end
  end
end
