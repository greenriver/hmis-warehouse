###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO: START_ACL remove after ACL migration is complete
class GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy
  include Memery
  attr_reader :user

  def initialize(user:, access_group_ids:)
    @user = user
    @access_group_ids = access_group_ids
  end

  Role.permissions.each do |permission|
    method_name = :"#{permission}?"
    define_method method_name do
      # check if the user has permission on any role
      return false unless user.public_send(method_name)

      # check if the user in in any of the access groups
      user.access_groups.where(id: @access_group_ids).exists?
    end
    memoize :"#{permission}?"
  end
end
# END_ACL
