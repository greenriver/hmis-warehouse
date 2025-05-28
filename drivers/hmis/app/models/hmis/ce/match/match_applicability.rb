###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The `MatchApplicability` class determines whether a Coordinated Entry (CE) rule applies to a given entity
# (e.g., Opportunity, Unit, Unit Group, Project, or Organization) based on project criteria.
#
# This is NOT determining client is eligibility itself; rather it determines which rules to use for eligibility/priority.
#
# This class evaluates applicability rules for entities by checking:
# - Whether the rule's owner matches the entity or one of its parent entities.
# - Whether the entity's project type matches the rule's allowed project types.
# - Whether the entity's project funders match the rule's allowed funders.
#
# Note:
# - This class does NOT determine client eligibility itself; it determines which rules
#   should be used for eligibility/priority.
# - It supports evaluation against various entities (eg Project, Unit, etc) to support viewing applicable
#   rules for each entity type.
# - Global and Data Source-level rules are not yet supported (e.g. "all PSH projects in a data source")
#
# Example Use Case:
# - Determine whether a CE rule applies to a given Opportunity based on its associated Project and Organization.
# - Determine which rules apply to a specific Project, to display them on the Project's detail page.
###

#
# @attr [Object] owner Entity that owns/manages this applicability rule
# @attr [Array<String>] project_types List of valid project types
# @attr [Array<String>] project_funders List of valid project funder IDs

# This evaluates against Unit instead of Opportunity b/c should be able to view Eligibility rules for a Unit even if it doesn't have an active opportunity.
# Note: Does not yet support global or DataSource-level rules, for example "all PSH projects in data source"
module Hmis::Ce::Match
  MatchApplicability = Struct.new(:owner, :project_types, :project_funders, keyword_init: true) do
    def call(entity) # Opportunity, Unit, Unit Group, Project, or Organization
      project = determine_project(entity)

      owner_matches = owner_matches_entity?(entity) # One of Entity's ancestors is the owner of this Rule
      return owner_matches if project.nil? # Entity might not have a specific project (e.g. Organization)

      owner_matches && # Rule Owner matches this entity (directly or through parent record)
      matches_project_type?(project) && # Project type matches or is unspecified
      matches_project_funders?(project) # Project funders match or are unspecified
    end

    protected

    # Checks whether the rule `owner` match this entity.
    # Checks all parent records, i.e. will return true for a Unit if the rule is set on that unit's Project
    def owner_matches_entity?(entity) # Opportunity, Unit, Unit Group, Project, or Organization
      raise unless owner # unexpected, owner is required in db

      gather_parents(entity).any? { |potential_owner| potential_owner == owner }
    end

    def matches_project_type?(project)
      project_types.blank? || project_types.include?(project.project_type)
    end

    def matches_project_funders?(project)
      project_funders.blank? || (project_funders & project.funders.map(&:funder)).any?
    end

    private

    def determine_project(entity)
      case entity
      when Hmis::Ce::Opportunity, Hmis::Unit, Hmis::UnitGroup
        entity.project
      when Hmis::Hud::Project
        entity
      when Hmis::Hud::Organization
        nil
      else
        raise "Unexpected entity type for CE rule evaluation: #{entity.class.name}"
      end
    end

    # Find all ancestor records. If the Rule's "owner" is any of these records, then the rule applies to this entity.
    def gather_parents(entity)
      parents = case entity
      when Hmis::Ce::Opportunity
        unit = entity.owner
        raise "Expected opportunity owner to be a Unit, but found #{unit.class.name}" unless unit.is_a?(Hmis::Unit)

        [unit, unit.unit_group, unit.project, unit.project.organization]
      when Hmis::Unit
        [entity, entity.unit_group, entity.project, entity.project.organization]
      when Hmis::UnitGroup
        [entity, entity.project, entity.project.organization]
      when Hmis::Hud::Project
        [entity, entity.organization]
      when Hmis::Hud::Organization
        [entity]
      else
        raise "Unexpected entity type for CE rule evaluation: #{entity.class.name}"
      end
      parents
    end
  end
end
