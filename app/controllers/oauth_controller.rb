class OauthController < ApplicationController
  skip_before_action :authenticate_user!

  layout false

  before_action -> { doorkeeper_authorize!(:user_profile) }

  def user
    user = User.find(doorkeeper_token.resource_owner_id)

    render(json: { id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email })
  end
end
