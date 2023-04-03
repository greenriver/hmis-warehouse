###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/boston-cas/blob/production/LICENSE.md
###

class CasAccess::EntityViewPermission < CasBase
  self.table_name = :entity_view_permissions
  acts_as_paranoid

  belongs_to :entity, polymorphic: true
  belongs_to :user
  belongs_to :agency
end
