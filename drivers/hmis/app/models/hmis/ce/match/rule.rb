# frozen_string_literal: true

# requirement configuration for opportunities

# This model represents a Rule for Coordinated Entry (CE) matching, such as eligibility requirements
# and priority schemes.
#
# Rules are associated with an "owner" (e.g., a unit, project, or organization),
# which determines the scope of applicability. The `applicability_config` can further refine this
# scope by specifying conditions like project types or funders.
#
# Examples:
#
#    Rule Applies to All Emergency Shelter (ES) Projects in HMIS:
#      { owner: hmis_data_source, applicability_config: { project_types: [0, 1] } }
#
#    Rule Applies to All Projects in Organization Y:
#      { owner: organization_y, applicability_config: {} }
#
#    Rule Applies to All VA-funded Projects in Organization Y:
#      { owner: organization_y, applicability_config: { project_funders: [37, 38, 39] } }
#
# The `for_entity` and `for_opportunity` methods allow querying rules that apply to specific entities or opportunities.
module Hmis::Ce::Match
  class Rule < GrdaWarehouseBase
    self.table_name = 'ce_match_rules'

    belongs_to :owner, polymorphic: true

    validates :name, presence: true
    validates :rank, uniqueness: { scope: [:owner_type, :owner_id], allow_nil: true }

    ELIGIBILITY_REQUIREMENT = 'eligibility_requirement'
    PRIORITY_SCHEME = 'priority_scheme'
    validates :rule_type, presence: true, inclusion: { in: [ELIGIBILITY_REQUIREMENT, PRIORITY_SCHEME] }

    validate :ensure_rank

    scope :by_rank, -> { order(:rank) }

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

    private

    def ensure_rank
      errors.add(:rank, 'is required for priority schemes') if priority_scheme? && rank.blank?
      errors.add(:rank, 'should only be set for priority schemes') if eligibility_requirement? && rank.present?
    end
  end
end
