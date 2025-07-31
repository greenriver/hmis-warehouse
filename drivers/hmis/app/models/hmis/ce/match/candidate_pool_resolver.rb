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

      # Find the most specific priority schemes by owner type
      priority_rules = rules.filter(&:priority_scheme?)
      most_specific_priority_rules = most_specific_rules(priority_rules)
      priority_expressions = most_specific_priority_rules.sort_by(&:rank).map(&:expression)
      key << priority_expressions.join('|||') || '0'

      # Eligibility requirements use all applicable rules (no specificity filtering)
      key << (rules.filter(&:eligibility_requirement?).map(&:expression).join(' AND ') || 'TRUE')
      key
    end

    def most_specific_rules(rules)
      return [] if rules.empty?

      # Owner specificity hierarchy: unit > unit_group > project > organization > data_source
      specificity_order = {
        'Hmis::Unit' => 1,
        'Hmis::UnitGroup' => 2,
        'Hmis::Hud::Project' => 3,
        'Hmis::Hud::Organization' => 4,
        'GrdaWarehouse::DataSource' => 5,
      }

      # Group by specificity and return the most specific group
      most_specific_level = rules.map { |rule| specificity_order[rule.owner.class.name] || 999 }.min
      rules.select { |rule| (specificity_order[rule.owner.class.name] || 999) == most_specific_level }
    end
  end
end
