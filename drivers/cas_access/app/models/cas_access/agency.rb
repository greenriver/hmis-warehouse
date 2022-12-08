###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Agency < CasBase
    self.table_name = :agencies
    has_many :users
    has_many :entity_view_permissions

    def program_ids
      entity_view_permissions.where(entity_type: 'Program').pluck(:entity_id)
    end
  end
end
