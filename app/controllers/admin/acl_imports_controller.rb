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
    @imports = import_scope.order(created_at: :desc).preload(:user)
    @pagy, @imports = pagy(@imports)
  end

  def show
  end

  def create
    @import = import_scope.create!(import_params.merge(user_id: current_user.id, status: AccessControlUpload::UPLOADED))
    @import.delay(queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)).pre_process!
    respond_with(@import, location: admin_acl_imports_path)
  end

  # Completes the import using the file specified
  def update
    if @import.pending_import?
      @import.delay(queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)).import!
      @import.update(status: AccessControlUpload::IMPORTING)
    else
      flash[:notice] = 'This import is not ready to be processed, or has already been completed.'
    end
    respond_with(@import, location: admin_acl_imports_path)
  end

  def destroy
    @import.destroy!
    respond_with(@import, location: admin_acl_imports_path)
  end

  def sample
    send_file('spec/fixtures/files/access_control_imports/access_control_upload.xlsx', type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', disposition: 'attachment')
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
