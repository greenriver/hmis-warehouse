#
class GrdaWarehouse::AuthPolicies::GlobalPolicy
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  Role.permissions.each do |permission|
    delegate "#{permission}?", to: :user
  end
end
