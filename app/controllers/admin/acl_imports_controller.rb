###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Admin::AclImportsController < ApplicationController
  include ViewableEntities
  include ArelHelper

  before_action :require_can_edit_users!
  before_action :set_import, only: [:show, :update, :destroy]

  def index
    @imports = import_scope.preload(:user)
    @pagy, @imports = pagy(@imports)
  end

  def show
  end

  def create
    @import = import_scope.create!(import_params.merge(user_id: current_user.id))
    respond_with(@import, location: admin_acl_imports_path)
  end

  # Completes the import using the file specified
  def update
    raise 'TODO; implement me'
    # respond_with(@import, location: admin_acl_imports_path)
  end

  def destroy
    @import.destroy
    respond_with(@import, location: admin_acl_imports_path)
  end

  private def import_scope
    AccessControlUpload.all
  end

  private def import_params
    params.require(:access_controls).
      permit(:file)
  end

  private def set_import
    @import = import_scope.find(params[:id].to_i)
  end
end
