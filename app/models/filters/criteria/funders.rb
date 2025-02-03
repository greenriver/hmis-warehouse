class Filters::Criteria::Funders < Filters::Criteria::Base
  LEVEL = :project

  attribute :funder_ids, :array

  def apply(scope)
    project_ids = GrdaWarehouse::Hud::Funder.joins(:project)
      .where(funder: funder_ids)
      .select(arel.p_t[:id])
    scope.in_project(project_ids)
  end

end
