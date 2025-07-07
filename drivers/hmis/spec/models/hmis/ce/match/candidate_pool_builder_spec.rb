# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilder, type: :model do
  let(:builder) { described_class.new(Hmis::Ce::Opportunity.all) }

  describe '#perform' do
    context 'with orphaned candidate pools' do
      let(:expiration_days) { 30 }
      let!(:old_orphaned_pool) do
        create(:hmis_ce_match_candidate_pool, configuration_updated_at: (expiration_days + 1).days.ago)
      end
      let!(:new_orphaned_pool) do
        create(:hmis_ce_match_candidate_pool, configuration_updated_at: (expiration_days - 1).days.ago)
      end
      let!(:active_pool) { create(:hmis_ce_match_candidate_pool, configuration_updated_at: (expiration_days + 1).days.ago) }
      let!(:opportunity) { create(:hmis_ce_opportunity, candidate_pool: active_pool) }

      before do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:days_to_retain_orphan_candidate_pools).and_return(expiration_days)
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      end

      it 'deletes old orphaned pools' do
        expect { builder.perform }.to change(Hmis::Ce::Match::CandidatePool, :count).by(-1)
        expect(Hmis::Ce::Match::CandidatePool.exists?(old_orphaned_pool.id)).to be_falsey
      end

      it 'does not delete new orphaned pools' do
        builder.perform
        expect(Hmis::Ce::Match::CandidatePool.exists?(new_orphaned_pool.id)).to be_truthy
      end
    end
  end
end
