# frozen_string_literal: true

class Filters::Criteria::FilterForOrganizations < Filters::Criteria::Base
  def applies?
    input.organization_ids.present? && user.report_filter_visible?(:organization_ids)
  end

  def apply(scope)
    scope = super(scope)
    scope.merge(GrdaWarehouse::Hud::Organization.viewable_by(user)).
      in_organization(input.organization_ids)
  end
end
