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
        return none unless user.can_view_full_client_dashboard?
        return none unless user.can_view_limited_client_dashboard?

        joins(:source_client).
          merge(source_visible_to(user))
      end

      scope :source_visible_to, ->(user) do
        return none unless user
        return none unless user.can_view_full_client_dashboard?
        return none unless user.can_view_limited_client_dashboard?

        where(
          id: active_confirmed_consent_in_cocs(user.coc_codes).
          joins(:warehouse_client).select(:source_id),
        ).
          or(joins(:enrollment).visible_to(user))
        # TODO: handle authoritative clients
        # Arbiter
      end
    end
  end
end
