###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasAccess
  class UserRole < CasBase
    self.table_name = :user_roles
    acts_as_paranoid

    belongs_to :user, inverse_of: :user_roles
    belongs_to :role, inverse_of: :user_roles
  end
end
