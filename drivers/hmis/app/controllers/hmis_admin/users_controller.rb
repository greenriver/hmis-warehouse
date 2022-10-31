###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::UsersController < ApplicationController
  include ViewableEntities
  include EnforceHmisEnabled

  before_action :require_hmis_admin_access!
  before_action :set_user, only: [:edit, :update]
  after_action :log_user, only: [:edit, :update]

  def index
  end

  def edit
  end

  def update
  end
end
