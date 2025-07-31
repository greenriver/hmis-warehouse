# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Candidate, type: :model do
  describe '.prioritized' do
    let!(:data_source) { create(:hmis_data_source) }
    let!(:candidate_pool) { create(:hmis_ce_match_candidate_pool) }

    let!(:candidate1) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, priority_scores: [3, 2, 1]) }
    let!(:candidate2) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, priority_scores: [3, 2, 2]) }
    let!(:candidate3) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, priority_scores: [3, 3]) }
    let!(:candidate4) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, priority_scores: [3]) }

    it 'orders by priority_scores element by element' do
      ordered_candidates = described_class.prioritized

      # Expected order:
      # 1. [3, 3] - candidate3
      # 2. [3, 2, 2] - candidate2
      # 3. [3, 2, 1] - candidate1
      # 4. [3] - candidate4

      expect(ordered_candidates.pluck(:id)).to eq([candidate3.id, candidate2.id, candidate1.id, candidate4.id])
    end
  end
end
