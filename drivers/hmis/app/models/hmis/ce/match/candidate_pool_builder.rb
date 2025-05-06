# frozen_string_literal: true

# update candidate pools to reflect the current opportunities, requirements and priority configuration

module Hmis::Ce::Match
  class CandidatePoolBuilder
    def initialize(opportunities)
      @opportunities = opportunities
    end

    # Optimization TBD. Assumes a relatively small number of active opportunities (1,000 or less)
    def perform
      with_lock do
        Hmis::Ce::Match::CandidatePool.transaction do
          _perform
        end
      end
    end

    protected

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 30, &block)
    end

    def _perform
      # Group opportunities by unique priority and eligibility rules.
      # Key is an array of priority schemes and eligibility requirements;
      # Value is an array of opportunities matching those rules.
      # For example,
      # {
      #   ["days_homeless", "current_age >= 18"] => [opportunity1, opportunity2, ...]
      # }
      grouped = {}

      all_rules = Hmis::Ce::Match::Rule.preload(:owner).order(:owner_type, :id).to_a
      @opportunities.preload(project: [:organization, :funders]).each do |opportunity|
        rules = all_rules.filter { |rule| rule.applies_to_opportunity?(opportunity) }
        key = []
        key << (rules.filter(&:priority_scheme?).first&.expression || '0')
        key << (rules.filter(&:eligibility_requirement?).map(&:expression).join(' AND ') || 'TRUE')

        grouped[key] ||= []
        grouped[key] << opportunity
      end

      update_pools!(grouped.keys)
      update_opportunity_pools!(grouped)
      cleanup_orphan_pools
    end

    def update_opportunity_pools!(grouped)
      current_pools = Hmis::Ce::Match::CandidatePool.order(:id).to_a.index_by do |pool|
        [pool.priority_expression, pool.requirement_expression]
      end
      grouped.each do |key, opportunities|
        pool = current_pools.fetch(key)
        @opportunities.where(id: opportunities.map(&:id)).update_all(candidate_pool_id: pool.id)
      end
    end

    def now
      @now ||= Time.current
    end

    def update_pools!(values)
      attrs = values.map do |priority_expression, requirement_expression|
        {
          priority_expression: priority_expression,
          requirement_expression: requirement_expression,
          configuration_updated_at: now,
        }
      end
      result = Hmis::Ce::Match::CandidatePool.import(
        attrs,
        on_duplicate_key_update: {
          conflict_target: [:priority_expression, :requirement_expression],
          columns: [:configuration_updated_at],
        },
      )
      raise "Failed: #{result.failed_instances}" if result.failed_instances.present?
    end

    # delete pools that haven't been used in a while
    def cleanup_orphan_pools
      duration = Hmis::Ce.configuration.days_to_retain_orphan_candidate_pools
      return unless duration

      expiration_date = now - duration.days
      Hmis::Ce::Match::CandidatePool.
        where(configuration_updated_at: ...expiration_date).
        find_each(&:destroy!)
    end
  end
end
