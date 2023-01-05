###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Role < CasBase
    self.table_name = :roles
    has_many :user_roles, dependent: :destroy, inverse_of: :role
    has_many :users, through: :user_roles

    # Used to determine if we should limit reporting
    # to one agency or not
    scope :match_admin, -> do
      where(can_reject_matches: true)
    end
  end
end
