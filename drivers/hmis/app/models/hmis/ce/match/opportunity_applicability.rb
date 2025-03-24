# Determines whether a CE rule applies to a given opportunity based on project criteria. This is NOT determining
# client is eligibility itself; rather it determines what rule configurations to use for eligibility/priority
#
# @attr [Object] owner Entity that owns/manages this applicability rule
# @attr [Array<String>] project_types List of valid project types
# @attr [Array<String>] project_funders List of valid project funder IDs

# frozen_string_literal: true

module Hmis::Ce::Match
  OpportunityApplicability = Struct.new(:owner, :project_types, :project_funders, keyword_init: true) do
    def call(opportunity)
      project = opportunity.project

      matches_owner?(opportunity) &&
      matches_project_type?(project) &&
      matches_project_funders?(project)
    end

    protected

    def matches_owner?(opportunity)
      owner == opportunity ||
      owner == opportunity.project ||
      owner == opportunity.project.organization
    end

    def matches_project_type?(project)
      project_types.blank? || project_types.include?(project.project_type)
    end

    def matches_project_funders?(project)
      project_funders.blank? || (project_funders & project.funders.map(&:funder)).any?
    end
  end
end
