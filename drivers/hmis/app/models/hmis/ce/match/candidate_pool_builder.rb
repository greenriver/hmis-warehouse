# frozen_string_literal: true

# Synchronizes candidate pools with the current set of opportunities and their matching rules.
#
# Candidate pools group opportunities that share the same eligibility requirements and
# prioritization schemes. This allows the CE matching engine to efficiently evaluate
# clients against multiple similar opportunities at once.
#
# The builder:
# 1. Creates new pools for unique rule combinations that don't exist yet
# 2. Assigns opportunities to their correct pools based on current rules
# 3. Flags opportunities as "stale" when their rules have changed
# 4. Cleans up orphaned pools that are no longer needed
#
module Hmis::Ce::Match
  class CandidatePoolBuilder
    def initialize(opportunities)
      @opportunities = opportunities
      @all_rules = nil
      @opportunity_rules = {}
    end

    # Optimization TBD. Assumes a relatively small number of active opportunities (1,000 or less)
    def perform
      updated_ids = []
      with_lock do
        Hmis::Ce::Match::CandidatePool.transaction do
          updated_ids = _perform
        end
      end
      updated_ids
    end

    protected

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 30, &block)
    end

    def _perform
      grouped = opportunities_by_key(opportunity_scope: @opportunities)
      created_ids = create_new_pools!(grouped.keys)
      update_opportunity_pools!(grouped)
      cleanup_orphan_pools
      created_ids
    end

    # Update the opportunity records with their candidate pools
    def update_opportunity_pools!(grouped)
      current_pools = load_candidate_pools_by_key

      # Collect all opportunity updates for a single upsert
      opportunity_updates = []

      grouped.each do |key, opportunities|
        target_pool = current_pools.fetch(key)

        opportunities.each do |opportunity|
          attrs = opportunity.attributes.symbolize_keys
          if opportunity.candidate_pool_id.nil?

            # New opportunity - assign to pool and capture the current rules for historical reporting
            opportunity_updates << attrs.merge(
              {
                candidate_pool_id: target_pool.id,
                stale: false,
                assignment_rules: opportunity_rules(opportunity).map(&:attributes),
              },
            )
          elsif opportunity.candidate_pool_id != target_pool.id
            # Existing opportunity - rules changed, flag as stale but don't change pool
            opportunity_updates << attrs.merge({ stale: true })
          elsif opportunity.stale?
            # Opportunity already in correct pool - ensure it's not flagged
            opportunity_updates << attrs.merge({ stale: false })
          end
        end
      end

      # Perform single bulk upsert if there are updates
      return unless opportunity_updates.any?

      result = Hmis::Ce::Opportunity.import!(
        opportunity_updates,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:candidate_pool_id, :stale, :assignment_rules],
        },
      )
      raise "Failed to update CE Opportunities: #{result.inspect}" if result.failed_instances.present?
    end

    def now
      @now ||= Time.current
    end

    # Create candidate pools, if they don't exist, for the given [priority, requirement] keys
    # Returns the IDs of newly created pools
    def create_new_pools!(values)
      attrs = values.map do |priority_expression, requirement_expression|
        {
          priority_expression: priority_expression,
          requirement_expression: requirement_expression,
        }
      end
      result = Hmis::Ce::Match::CandidatePool.import(
        attrs,
        on_duplicate_key_ignore: {
          conflict_target: [:priority_expression, :requirement_expression],
        },
      )
      raise "Failed: #{result.failed_instances}" if result.failed_instances.present?

      result.ids
    end

    # Delete pools that haven't been used in a while
    def cleanup_orphan_pools
      duration = Hmis::Ce.configuration.days_to_retain_orphan_candidate_pools
      return unless duration

      expiration_date = now - duration.days
      Hmis::Ce::Match::CandidatePool.
        orphaned.
        where(updated_at: ...expiration_date).
        find_each(&:destroy!)
    end

    # Migrated from CandidatePoolResolver
    def all_rules
      # Cache all Rules in an instance variable to reduce database hits
      @all_rules ||= Hmis::Ce::Match::Rule.preload(:owner).order(:owner_type, :id).to_a
    end

    def opportunities_by_key(opportunity_scope:)
      # Group the given opportunities by unique priority and eligibility rules.
      # Key is an array of priority schemes and eligibility requirements;
      # Value is an array of opportunities matching those rules.
      # For example,
      # {
      #   ["{days_homeless}", "current_age >= 18"] => [opportunity1, opportunity2, ...]
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
    def load_candidate_pools_by_key
      Hmis::Ce::Match::CandidatePool.all.index_by do |pool|
        [pool.priority_expression, pool.requirement_expression]
      end
    end

    def opportunity_rules(opportunity)
      @opportunity_rules[opportunity.id] ||= all_rules.filter { |rule| rule.applies_to_entity?(opportunity) }
    end

    # Generates a unique key for an opportunity based on its applicable rules
    # Returns an array of [priority_expression, eligibility_expression]
    def key_for_opportunity(opportunity:)
      rules = opportunity_rules(opportunity)

      key = []
      key << priority_expression_for_rules(rules)
      key << eligibility_expression_for_rules(rules)
      key
    end

    # Transform multiple priority scheme rules into a single expression that returns a Dentaky array {item1, item2, ...}
    def priority_expression_for_rules(rules)
      expressions = priority_rules(rules).
        sort_by { |r| [r.rank, r.id] }.
        map(&:expression)
      "{#{expressions.join(', ')}}"
    end

    # Transform multiple eligibility requirement rules into a single expression
    # Multiple rules are combined with AND logic
    def eligibility_expression_for_rules(rules)
      expressions = rules.filter(&:eligibility_requirement?).
        sort_by(&:id).
        map(&:expression)

      return 'TRUE' if expressions.empty?

      expressions.join(' AND ')
    end

    # An opportunity can respect multiple priority rules, with different `rank` values.
    # However, an opportunity can't respect multiple different rules with different owners,
    # because `rank` is unique on owner, not unique globally.
    # This function filters down the list of priority rules that apply to this opportunity:
    # If there are rules defined with different owners, pick the most specific owner,
    # and return all rules applying to that owner
    def priority_rules(rules)
      rules = rules.filter(&:priority_scheme?)
      return [] if rules.empty?

      # Owner specificity hierarchy: unit_group > project > organization > data_source
      specificity_order = {
        'Hmis::UnitGroup' => 1,
        'Hmis::Hud::Project' => 2,
        'Hmis::Hud::Organization' => 3,
        'GrdaWarehouse::DataSource' => 4,
      }

      # Group by specificity and return the most specific group
      most_specific_level = rules.map { |rule| specificity_order[rule.owner.class.name] || 999 }.min
      rules.select { |rule| (specificity_order[rule.owner.class.name] || 999) == most_specific_level }
    end
  end
end
