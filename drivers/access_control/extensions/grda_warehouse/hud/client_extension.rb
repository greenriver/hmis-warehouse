###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AccessControl::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :destination_visible_to, ->(user) do
        return none unless user
        return none unless user.can_view_full_client_dashboard? || user.can_view_limited_client_dashboard?

        joins(:source_clients).
          merge(source_visible_to(user))
      end

      scope :source_visible_to, ->(user) do
        return none unless user
        return none unless user.can_view_full_client_dashboard? || user.can_view_limited_client_dashboard?

        from_source_enrollments = joins(:enrollments).
          merge(GrdaWarehouse::Hud::Enrollment.visible_to(user)).select(:id)
        from_roi = active_confirmed_consent_in_cocs(user.coc_codes).joins(:warehouse_client_source).select(:source_id)
        where(arel_table[:id].in(Arel.sql(from_source_enrollments.to_sql)).
          or(arel_table[:id].in(Arel.sql(from_roi.to_sql))))
        # TODO: handle authoritative clients
        # Arbiter
      end
    end
  end
end
