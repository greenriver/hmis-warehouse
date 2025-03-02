# frozen_string_literal: true

class Filters::Criteria::FilterForFunders < Filters::Criteria::Base
  def applies?
    return false unless input.funder_ids.present? || input.funder_others.present?

    user.report_filter_visible?(:funder_ids) || user.report_filter_visible?(:funder_others)
  end

  def apply(scope)
    scope = super(scope)
    funder_scope = GrdaWarehouse::Hud::Funder.
      viewable_by(user, permission: :can_view_assigned_reports).
      joins(:project)
    funder_scope = funder_scope.where(Funder: input.funder_ids) if input.funder_ids.any?
    funder_scope = funder_scope.where(OtherFunder: input.funder_others) if input.funder_others.any?
    project_ids = funder_scope.select(arel.p_t[:id])
    scope.in_project(project_ids)
  end
end
