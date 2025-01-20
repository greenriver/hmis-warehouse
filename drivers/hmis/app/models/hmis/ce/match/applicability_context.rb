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
      owner == owner.project ||
      owner == owner.project.organization
    end

    def matches_project_type?(project)
      project_type.blank? || project.project_type.in(project_types)
    end

    def matches_project_funders?(project)
      project_funders.blank? || project_funder_ids & project.project_funders.map(&:funder_id)
    end
  end
end
