###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
