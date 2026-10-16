###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForOrganizations < Filters::Criteria::Base
  def applies?
    input.organization_ids.present? && user.report_filter_visible?(:organization_ids)
  end

  def apply(scope)
    scope = super(scope)
    # Viewable and selected organizations in one merge; merging them separately lets the
    # second `where` on the organization id replace the first
    scope.joins(:organization).
      merge(GrdaWarehouse::Hud::Organization.viewable_by(user, permission: :can_view_assigned_reports).where(id: input.organization_ids))
  end
end
