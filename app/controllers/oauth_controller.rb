class OauthController < ApplicationController
  skip_before_action :authenticate_user!

  layout false

  before_action -> { doorkeeper_authorize! :user_profile }, only: [:user]

  def user
    user = User.find(doorkeeper_token.resource_owner_id)

    render(json: { id: user.id, name: user.name, email: user.email })
  end
end
