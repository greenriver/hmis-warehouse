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

    # lower numbers have a higher priority
    OWNER_PRECEDENCE = {
      'Hmis::UnitGroup' => 1,
      'Hmis::Hud::Project' => 2,
      'Hmis::Hud::Organization' => 3,
      'GrdaWarehouse::DataSource' => 4,
    }.freeze

    belongs_to :owner, polymorphic: true
    validates :owner_type, inclusion: { in: OWNER_PRECEDENCE.keys }
    validate :owner_is_not_changed, on: :update
    validate :rule_type_is_not_changed, on: :update

    validates :name, presence: true
    validates :rank, uniqueness: { scope: [:owner_type, :owner_id], allow_nil: true }

    ELIGIBILITY_REQUIREMENT = 'eligibility_requirement'
    PRIORITY_SCHEME = 'priority_scheme'
    validates :rule_type, presence: true, inclusion: { in: [ELIGIBILITY_REQUIREMENT, PRIORITY_SCHEME] }
    validate :ensure_rank

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
      owner_type_case = Arel::Nodes::Case.new(arel_table[:owner_type])
      OWNER_PRECEDENCE.each do |owner_type, order|
        owner_type_case = owner_type_case.when(owner_type).then(order)
      end
      owner_type_case = owner_type_case.else(99)

      order(owner_type_case, :id)
    end

    def owner_precedence
      OWNER_PRECEDENCE.fetch(owner_type, 99)
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
      all_rules = by_owner_precedence.preload(:owner).to_a
      all_rules.filter { |rule| rule.applies_to_entity?(entity) }
    end

    # Returns only the most specific owner level priority schemes from a provided rule set,
    # ordered by [rank, id]. If ranks are nil (e.g., during transitional states), they are
    # treated as lowest priority for stable ordering.
    def self.most_specific_priority_schemes_from(rules)
      priority_rules = rules.select(&:priority_scheme?).sort_by { |r| [r.rank || Float::INFINITY, r.id] }
      return [] if priority_rules.empty?

      most_specific_level = priority_rules.map(&:owner_precedence).min
      priority_rules.select { |r| r.owner_precedence == most_specific_level }
    end

    # Helper for GraphQL resolvers: return eligibility requirements applicable to an entity
    def self.eligibility_requirements_for_entity(entity)
      for_entity(entity).select(&:eligibility_requirement?)
    end

    # Helper for GraphQL resolvers: return most specific, rank-ordered priority schemes
    def self.priority_schemes_for_entity(entity)
      most_specific_priority_schemes_from(for_entity(entity))
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
      Hmis::Ce::Match::CandidatePool.lock_for_maintenance! do
        Hmis::Ce::Match::CandidatePoolBuilder.call
      end
    end

    def ensure_rank
      errors.add(:rank, 'is required for priority schemes') if priority_scheme? && rank.blank?
      errors.add(:rank, 'should only be set for priority schemes') if eligibility_requirement? && rank.present?
    end
  end
end
