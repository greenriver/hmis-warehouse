# update candidate pools to reflect the current opportunities, requirements and priority configuration

module Hmis::Ce::Match
  class CandidatePoolBuilder
    # assumes a relatively small number of active opportunities
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
      grouped = {}

      Hmis::Ce::Match::Rule.order(:owner_type, :id)
      # group opportunities by unique priority and eligibility rules
      active_opportunities.each do |opportunity|
        rules = Hmis::Ce::Match::Rule.all.to_a.filter { |rule| rule.applies_to_opportunity?(opportunity) }
        key = []
        key << (rules.filter(&:priority_scheme?).map(&:expression).join(' AND ') || 'TRUE')
        key << (rules.filter(&:eligibility_requirement?).first&.expression || '0')

        grouped[key] ||= []
        grouped[key] << opportunity
      end

      update_pools!(grouped.keys)
      update_opportunity_pools!(grouped)
    end

    def update_opportunity_pools!(grouped)
      current_pools = Hmis::Ce::Match::CandidatePool.order(:id).to_a.index_by do |pool|
        [pool.priority_expression, pool.requirement_expression]
      end
      grouped.each do |key, opportunities|
        pool = current_pools.fetch(key)
        active_opportunities.where(id: opportunities.map(&:id)).update_all(candidate_pool_id: pool.id)
      end
    end

    def active_opportunities
      Hmis::Ce::Opportunity.active
    end

    def update_pools!(values)
      now = Time.current
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

      # delete pools that haven't been used in a while
      Hmis::Ce::Match::CandidatePool.
        where(configuration_updated_at: ...(now - 6.months)).
        find_each(&:destroy!)
    end
  end
end
