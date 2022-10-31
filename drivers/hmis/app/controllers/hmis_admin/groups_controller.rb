###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::GroupsController < ApplicationController
  include ViewableEntities
  include EnforceHmisEnabled

  before_action :require_hmis_admin_access!
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
