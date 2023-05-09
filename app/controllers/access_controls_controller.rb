###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccessControlsController < ApplicationController
  include ViewableEntities
  include ArelHelper
  include AjaxModalRails::Controller

  before_action :set_access_control, only: [:show]

  def show
    @modal_size = :xl
  end

  private def access_control_scope
    AccessControl
  end

  private def set_access_control
    @access_control = access_control_scope.find(params[:id].to_i)
  end
end
