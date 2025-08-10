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
module Hmis::Ce::Match
  class Rule < GrdaWarehouseBase
    self.table_name = 'ce_match_rules'

    ALLOWED_OWNER_TYPES = ['Hmis::UnitGroup', 'Hmis::Hud::Project', 'Hmis::Hud::Organization'].freeze
    belongs_to :owner, polymorphic: true
    validates :owner_type, inclusion: { in: ALLOWED_OWNER_TYPES }
    validate :owner_is_not_changed, on: :update
    validate :rule_type_is_not_changed, on: :update

    validates :name, presence: true
    ELIGIBILITY_REQUIREMENT = 'eligibility_requirement'
    PRIORITY_SCHEME = 'priority_scheme'
    validates :rule_type, presence: true, inclusion: { in: [ELIGIBILITY_REQUIREMENT, PRIORITY_SCHEME] }

    after_create :rebuild_candidate_pools
    after_destroy :rebuild_candidate_pools
    after_update :rebuild_candidate_pools, if: :rule_logic_changed?

    # for revivified records, allow id override for safe client caching
    attr_accessor :graphql_id

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

    # Order rules by owner precedence (UnitGroup > Project > Organization) then by id
    # This ordering ensures deterministic rule resolution for consistent key generation
    scope :by_owner_precedence, -> do
      owner_type_case = Arel::Nodes::Case.new(arel_table[:owner_type]).
        when('Hmis::UnitGroup').then(0).
        when('Hmis::Hud::Project').then(1).
        when('Hmis::Hud::Organization').then(2).
        else(99)

      order(owner_type_case, :id)
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

    # Returns all rules applicable to the given entity (UnitGroup/Project/Organization),
    # considering owner lineage and applicability_config (project_types, project_funders).
    # Loads all rules and filters in Ruby to respect polymorphic owner lineage and config.
    def self.for_entity(entity)
      all_rules = preload(:owner).order(:owner_type, :id).to_a
      all_rules.filter { |rule| rule.applies_to_entity?(entity) }
    end

    private

    def owner_is_not_changed
      errors.add(:owner, 'cannot be changed') if will_save_change_to_owner_id? || will_save_change_to_owner_type?
    end

    def rule_type_is_not_changed
      errors.add(:rule_type, 'cannot be changed') if will_save_change_to_rule_type?
    end

    def rule_logic_changed?
      # For updates, only rebuild if relevant attributes changed.
      saved_change_to_rule_type? || saved_change_to_expression? || saved_change_to_applicability_config?
    end

    def rebuild_candidate_pools
      Hmis::Ce::Match::CandidatePool.lock_for_maintenance do
        Hmis::Ce::Match::CandidatePoolBuilder.new.perform
      end
    end
  end
end
