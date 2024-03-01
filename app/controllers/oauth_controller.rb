###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class OauthController < ApplicationController
  skip_before_action :authenticate_user!

  layout false

  before_action -> { doorkeeper_authorize!(:user_data) }

  def user
    user = User.find(doorkeeper_token.resource_owner_id)

    payload = {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      superset_roles: user.superset_roles,
    }

    render(json: payload)
  end
end
