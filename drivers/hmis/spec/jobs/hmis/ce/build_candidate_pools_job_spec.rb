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
end
