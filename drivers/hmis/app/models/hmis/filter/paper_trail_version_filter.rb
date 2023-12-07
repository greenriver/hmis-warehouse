###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::PaperTrailVersionFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    filters = input
    scope = ensure_scope(scope)
    scope = scope.where(user_id: filters.user_id) if filters&.user_id&.present?
    scope = scope.where(item_type: filters.audit_event_record_type) if filters&.audit_event_record_type&.present?
    scope
  end
end
