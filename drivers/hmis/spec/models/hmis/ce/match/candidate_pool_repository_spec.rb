# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolRepository do
  subject(:repo) { described_class.new }

  describe '#all_by_key' do
    let!(:pool1) { create(:hmis_ce_match_candidate_pool, priority_expression: '0', requirement_expression: 'TRUE') }
    let!(:pool2) { create(:hmis_ce_match_candidate_pool, priority_expression: 'p', requirement_expression: 'r') }

    it 'returns a hash keyed by [priority, requirement]' do
      map = repo.all_by_key
      expect(map[[pool1.priority_expression, pool1.requirement_expression]].id).to eq(pool1.id)
      expect(map[[pool2.priority_expression, pool2.requirement_expression]].id).to eq(pool2.id)
    end
  end

  describe '#create_for_keys' do
    it 'creates pools for missing keys and is idempotent; clears cache' do
      keys = [['p1', 'r1'], ['p2', 'r2']]
      ids_first = repo.create_for_keys(keys)
      expect(ids_first.size).to eq(2)

      # Cache should be cleared; newly created pools should be visible
      map = repo.all_by_key
      expect(map[['p1', 'r1']]).to be_present
      expect(map[['p2', 'r2']]).to be_present

      # Call again should not create duplicates
      ids_second = repo.create_for_keys(keys)
      expect(ids_second).to be_empty
    end

    it 'creates only missing pools when some keys already exist' do
      # Pre-existing pool
      existing_pool = create(:hmis_ce_match_candidate_pool, priority_expression: 'p1', requirement_expression: 'r1')
      keys = [['p1', 'r1'], ['p2', 'r2']]

      # Should create one new pool and return only its ID
      new_ids = repo.create_for_keys(keys)
      expect(new_ids.size).to eq(1)

      newly_created_pool = Hmis::Ce::Match::CandidatePool.find(new_ids.first)
      expect(newly_created_pool.priority_expression).to eq('p2')
      expect(newly_created_pool.requirement_expression).to eq('r2')

      # Ensure original pool was not affected
      expect(repo.find_by_key(['p1', 'r1']).id).to eq(existing_pool.id)
    end

    it 'ignores nil keys' do
      expect(repo.create_for_keys([nil])).to eq([])
    end
  end

  describe '#find_by_key' do
    let!(:pool) { create(:hmis_ce_match_candidate_pool, priority_expression: 'p', requirement_expression: 'r') }

    it 'returns the pool for a valid key' do
      expect(repo.find_by_key(['p', 'r'])).to eq(pool)
    end

    it 'returns nil for nil key' do
      expect(repo.find_by_key(nil)).to be_nil
    end
  end
end
