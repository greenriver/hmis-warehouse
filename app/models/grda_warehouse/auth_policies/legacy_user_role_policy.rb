# TODO: START_ACL remove after ACL migration is complete
class GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  Role.permissions.each do |permission|
    method_name = :"#{permission}?"
    define_method method_name do
      !!user.public_send(method_name)
    end
  end
end
