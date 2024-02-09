###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::PaperTrailVersionFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    filters = input
    scope = ensure_scope(scope)
    v_t = GrdaWarehouse::Version.arel_table
    with_filter(scope, :user) do
      scope = scope.where(v_t[:user_id].in(filters.user).or(v_t[:whodunnit].in(filters.user)).or(v_t[:true_user_id].in(filters.user)))
    end
    # FIXME: filtering by `Service` only turns up HUD Services, not Custom Services
    record_types = [
      filters.try(:enrollment_record_type),
      filters.try(:client_record_type),
    ].flatten.compact
    scope = scope.where(item_type: record_types) if record_types&.present?
    scope
  end
end
