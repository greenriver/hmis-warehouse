# frozen_string_literal: true

# requirement configuration for opportunities

module Hmis::Ce::Match
  class Rule < GrdaWarehouseBase
    self.table_name = 'ce_match_rules'

    belongs_to :owner, polymorphic: true

    validates :name, presence: true
    ELIGIBILITY_REQUIREMENT = 'eligibility_requirement'
    PRIORITY_SCHEME = 'priority_scheme'
    validates :rule_type, presence: true, inclusion: { in: [ELIGIBILITY_REQUIREMENT, PRIORITY_SCHEME] }

    def eligibility_requirement?
      rule_type == ELIGIBILITY_REQUIREMENT
    end

    scope :eligibility_requirement, -> do
      where(rule_type: ELIGIBILITY_REQUIREMENT)
    end

    def priority_scheme?
      rule_type == PRIORITY_SCHEME
    end

    scope :priority_scheme, -> do
      where(rule_type: PRIORITY_SCHEME)
    end

    def applies_to_entity?(entity)
      config = applicability_config.symbolize_keys || {}
      applicability = MatchApplicability.new(
        owner: owner,
        project_types: config[:project_types],
        project_funders: config[:project_funders],
      )

      applicability.call(entity)
    end

    def self.for_entity(entity)
      all_rules = preload(:owner).order(:owner_type, :id).to_a
      all_rules.filter { |rule| rule.applies_to_entity?(entity) }
    end

    def self.for_opportunity(opportunity)
      for_entity(opportunity)
    end
  end
end
