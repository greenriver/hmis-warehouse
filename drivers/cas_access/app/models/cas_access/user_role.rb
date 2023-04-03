###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class UserRole < CasBase
    self.table_name = :user_roles
    acts_as_paranoid

    belongs_to :user, inverse_of: :user_roles
    belongs_to :role, inverse_of: :user_roles
  end
end
