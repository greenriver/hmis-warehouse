# frozen_string_literal: true

# Encapsulates shared logic for matching opportunities to candidate pools
module Hmis::Ce::Match
  class CandidatePoolResolver
    def all_rules
      # Cache all Rules in a class variable to reduce database hits
      @all_rules ||= Hmis::Ce::Match::Rule.preload(:owner).order(:owner_type, :id).to_a
    end

    def opportunities_by_key(opportunity_scope:)
      # Group the given opportunities by unique priority and eligibility rules.
      # Key is an array of priority schemes and eligibility requirements;
      # Value is an array of opportunities matching those rules.
      # For example,
      # {
      #   ["days_homeless", "current_age >= 18"] => [opportunity1, opportunity2, ...]
      # }
      grouped = {}

      opportunity_scope.preload(project: [:organization, :funders]).find_each do |opportunity|
        key = key_for_opportunity(opportunity: opportunity)
        grouped[key] ||= []
        grouped[key] << opportunity
      end

      grouped
    end

    # Cache candidate pools indexed by the same key as described above;
    def candidate_pools_by_key
      @candidate_pools_by_key ||= load_candidate_pools_by_key
    end

    # Also expose a method for the caller to reload the cache if candidate pools change
    def reload_candidate_pools_by_key
      @candidate_pools_by_key = load_candidate_pools_by_key
    end

    # Get the candidate pool for the given opportunity. Can return nil if no applicable pool exists yet.
    def candidate_pool_for_opportunity(opportunity:)
      key = key_for_opportunity(opportunity: opportunity)
      candidate_pools_by_key[key]
    end

    private

    def load_candidate_pools_by_key
      Hmis::Ce::Match::CandidatePool.order(:id).to_a.index_by do |pool|
        [pool.priority_expression, pool.requirement_expression]
      end
    end

    def key_for_opportunity(opportunity:)
      rules = all_rules.filter { |rule| rule.applies_to_entity?(opportunity) }
      key = []
      key << (rules.filter(&:priority_scheme?).first&.expression || '0')
      key << (rules.filter(&:eligibility_requirement?).map(&:expression).join(' AND ') || 'TRUE')
      key
    end
  end
end
