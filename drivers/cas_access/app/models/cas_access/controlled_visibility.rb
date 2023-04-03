###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/boston-cas/blob/production/LICENSE.md
###

module CasAccess::ControlledVisibility
  extend ActiveSupport::Concern

  included do
    has_many :entity_view_permissions, as: :entity

    scope :visible_by, ->(user) {
      return current_scope if user.can_view_programs?
      return none unless user.can_view_assigned_programs?

      evp_t = CasAccess::EntityViewPermission.arel_table
      joins(:entity_view_permissions).where(
        evp_t[:agency_id].eq(user.agency_id),
      )
    }

    scope :editable_by, ->(user) {
      return current_scope if user.can_edit_programs?
      return none unless user.can_edit_assigned_programs?

      evp_t = CasAccess::EntityViewPermission.arel_table
      joins(:entity_view_permissions).where(
        evp_t[:agency_id].eq(user.agency_id),
        evp_t[:editable].eq(true),
      )
    }

    scope :visible_by_agency, ->(agency) {
      evp_t = CasAccess::EntityViewPermission.arel_table
      joins(:entity_view_permissions).where(
        evp_t[:agency_id].eq(agency.id),
      )
    }

    scope :editable_by_agency, ->(agency) {
      evp_t = CasAccess::EntityViewPermission.arel_table
      joins(:entity_view_permissions).where(
        evp_t[:agency_id].eq(agency.id),
        evp_t[:editable].eq(true),
      )
    }
  end

  def visible_by? user
    entity_view_permissions.where(agency_id: user.agency_id).present?
  end

  def editable_by? user
    entity_view_permissions.where(agency_id: user.agency_id, editable: true).present?
  end
end
