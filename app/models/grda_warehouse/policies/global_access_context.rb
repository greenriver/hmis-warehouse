
#
class GrdaWarehouse::Policies::GlobalAccessContext
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def client_policy
    # for global context, the user model is the access_context
    @client_policy ||= GrdaWarehouse::Policies::ClientPolicy.new(user)
  end
end
