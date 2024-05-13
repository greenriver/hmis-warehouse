class GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  Role.permissions.each do |permission|
    delegate "#{permission}?", to: :user
  end
end
