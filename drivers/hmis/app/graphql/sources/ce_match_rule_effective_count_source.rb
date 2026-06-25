# frozen_string_literal: true

module Sources
  # Performantly resolves effective CE eligibility rule counts for the given owner.
  # "Effective" means the rules are applicable to the owner, not necessarily just rules owned by this owner.
  # For example, for a project, this returns the count of all rules owned by that project, its organization, and its data source.
  class CeMatchRuleEffectiveCountSource < GraphQL::Dataloader::Source
    # Mapping of owner classes to the lineage/associations needed to resolve their rule count.
    OWNER_LINEAGE_CONFIG = {
      Hmis::Hud::Organization.sti_name => {
        associations: [:data_source],
        lineage: ->(organization) { [organization, organization.data_source] },
      },
      Hmis::Hud::Project.sti_name => {
        associations: [:data_source, :organization, :funders],
        lineage: ->(project) { [project, project.organization, project.data_source] },
      },
      Hmis::UnitGroup.sti_name => {
        associations: [{ project: [:data_source, :organization, :funders] }],
        lineage: ->(unit_group) { [unit_group, unit_group.project, unit_group.project.organization, unit_group.project.data_source] },
      },
    }.freeze

    def initialize(owner_class:)
      @owner_class = owner_class
      @owner_config = OWNER_LINEAGE_CONFIG.fetch(owner_class.sti_name) do
        raise ArgumentError, "Unsupported CE match rule owner class: #{owner_class.name}"
      end
    end

    def fetch(owners)
      preload_owner_lineage(owners)
      rules = rules_for(owners).preload(:owner).to_a

      owners.map do |owner|
        # Check applies_to_entity? to filter rules by project type and funder applicability
        applicable_rules = rules.select { |rule| rule.applies_to_entity?(owner) }

        # Only count eligibility rules, since those are the only rules that are returned in the UI for now.
        eligibility_rule_count = applicable_rules.count(&:eligibility_requirement?)

        # TODO(#9337) - incorporate priority rules in the count when they are added to the UI
        # Filter priority rules by owner precedence, so that this data loader has
        # functional parity with Hmis::Ce::Match::Rule.eligibility_and_priority_rules_for_entity
        # priority_rule_count = Hmis::Ce::Match::Rule.most_specific_priority_schemes_from(applicable_rules).count

        eligibility_rule_count
      end
    end

    def self.batch_key_for(owner_class:)
      owner_class.sti_name
    end

    private

    def preload_owner_lineage(owners)
      ActiveRecord::Associations::Preloader.new(records: owners, associations: @owner_config[:associations]).call
    end

    def rules_for(owners)
      # For all the owners requested, get the full lineage of ancestors whose rules may apply to them
      owners.map { |owner| @owner_config[:lineage].call(owner) }.
        # Flatten the list and group by class. Creates a shape like:
        # { Hmis::Hud::Organization => [org1, org2, ...], Hmis::Hud::Project => [p1, project2, ...], ... }
        flatten.group_by(&:class).
        map do |owner_class, lineage_owners|
          # For each class, get all the rules owned by any owner of this class
          Hmis::Ce::Match::Rule.where(owner_type: owner_class.sti_name, owner_id: lineage_owners.map(&:id))
        end.
        # Combine all the OR conditions into a single SQL query
        inject(&:or)
    end
  end
end
