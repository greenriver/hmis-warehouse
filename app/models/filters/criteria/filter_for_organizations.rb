class Filters::Criteria::FilterForOrganizations < Filters::Criteria::Base
  def applies?
    input.organization_ids.present? && user.report_filter_visible?(:organization_ids)
  end

  def apply(scope)
    scope.in_organization(input.organization_ids).
      merge(GrdaWarehouse::Hud::Organization.viewable_by(user))
  end
end
