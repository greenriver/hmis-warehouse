###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::PaperTrailVersionFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    filters = input
    scope = ensure_scope(scope)
    v_t = GrdaWarehouse::Version.arel_table
    scope = scope.where(v_t[:user_id].in(filters.user).or(v_t[:whodunnit].in(filters.user)).or(v_t[:true_user_id].in(filters.user))) if filters&.user&.present?
    # FIXME: filtering by `Service` only turns up HUD Services, not Custom Services
    scope = scope.where(item_type: filters.audit_event_record_type) if filters&.audit_event_record_type&.present?
    scope
  end
end
