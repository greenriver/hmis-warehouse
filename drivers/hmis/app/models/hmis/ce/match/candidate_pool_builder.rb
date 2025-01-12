
# update pools to reflect the current opportunities, requirements and priority configuration

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
      default_priority_expression = '0' # default formula scores everything to zero
      default_requirement_expression = 'TRUE' # default requirement matches everything
      active_opportunities.each do |opportunity|
        requirements = opportunity.requirements
        key = [
          (opportunity.priority_scheme.expression.presence || default_priority_expression),
          (requirements.map(&:expression).sort.uniq.join('AND').presence || default_requirement_expression),
        ]
        grouped[key] ||= []
        grouped[key] << opportunity
      end

      update_pools!(grouped.keys)
      update_opportunity_pools!(grouped)
    end

    def update_opportunity_pools!(grouped)
      current_pools = Ce::Match::CandidatePool.order(:id).to_a.index_by do |pool|
        [pool.priority_expression, pool.requirement_expression]
      end
      grouped.each do |key, opportunities|
        pool = current_pools.fetch(key)
        active_opportunities.where(id: opportunities.map(&:id)).update_all(candidate_pool_id: pool_id)
      end
    end

    def active_opportunities
      Hmis::Hud::Opportunity.where.not(status: 'closed')
    end

    def update_pools!(values)
      now = Time.current,
      attrs = values.each do |priority_expression, requirement_expression|
        {
          priority_expression: priority_expression,
          requirement_expression: requirement_expression,
          configuration_updated_at: now,
        }
      end
      result = Ce::Match::CandidatePool.import(
        attrs,
        on_duplicate_key_update: {
          conflict_target: [:priority_expression, :requirement_expression],
          columns: [:configuration_updated_at],
        },
      )
      raise "Failed: #{result.failed_instances}" if result.failed_instances.present?

      # delete pools that haven't been used in a while
      Ce::Match::CandidatePool
        .where(configuration_updated_at: ...(now - 6.months))
        .find_each(&:destroy!)
    end
  end
end
