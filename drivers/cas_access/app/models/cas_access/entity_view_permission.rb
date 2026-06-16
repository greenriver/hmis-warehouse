###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CasAccess::EntityViewPermission < CasBase
  self.table_name = :entity_view_permissions
  acts_as_paranoid

  belongs_to :entity, polymorphic: true
  belongs_to :user
  belongs_to :agency
end
