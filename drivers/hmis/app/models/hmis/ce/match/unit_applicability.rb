# Determines whether a CE rule applies to a given Unit based on project criteria. This is NOT determining
# client is eligibility itself; rather it determines what rule configurations to use for eligibility/priority
#
# @attr [Object] owner Entity that owns/manages this applicability rule
# @attr [Array<String>] project_types List of valid project types
# @attr [Array<String>] project_funders List of valid project funder IDs

# frozen_string_literal: true

# I think this should all be adjusted to evaluate based on the Unit (and UnitGroup) instead of the Opportunity. You should be able to view Eligibility rules for a Unit even if it doesn't have an active opportunity. You should also be able to attached Eligibility rules to a Unit. Only question mark is making the "snapshot" of applicable Eligibility rules when an Opportunity is minted. Do we capture that somewhere already?
module Hmis::Ce::Match
  UnitApplicability = Struct.new(:owner, :project_types, :project_funders, keyword_init: true) do
    def call(unit)
      project = unit.project

      matches_owner?(unit) &&
      matches_project_type?(project) &&
      matches_project_funders?(project)
    end

    protected

    def matches_owner?(unit)
      return false if owner.nil?

      owner == unit ||                     # Rule is tied to Unit directly
      owner == unit.unit_group ||          # Rule id tied to Unit's UnitGroup
      owner == unit.project ||             # Rule id tied to Unit's Project
      owner == unit.project.organization   # Rule id tied to Unit's Organization
    end

    def matches_project_type?(project)
      project_types.blank? || project_types.include?(project.project_type)
    end

    def matches_project_funders?(project)
      project_funders.blank? || (project_funders & project.funders.map(&:funder)).any?
    end
  end
end
