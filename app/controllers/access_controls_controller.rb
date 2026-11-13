###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccessControlsController < ApplicationControllerV2
  include ViewableEntities
  include ArelHelper
  include AjaxModalRails::Controller

  authorize_with { current_user.can_edit_users? }
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
