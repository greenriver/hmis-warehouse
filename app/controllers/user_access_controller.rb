###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UserAccessController < ApplicationController
  include AjaxModalRails::Controller
  before_action :require_can_view_imports_projects_or_organizations!
  before_action :set_data_source

  def show
    @modal_size = :sm
    @users = @data_source.users_with_view_access
  end

  private def data_source_scope
    GrdaWarehouse::DataSource.viewable_by(current_user)
  end

  private def set_data_source
    @data_source = data_source_scope.find(params[:data_source_id].to_i)
  end
end
