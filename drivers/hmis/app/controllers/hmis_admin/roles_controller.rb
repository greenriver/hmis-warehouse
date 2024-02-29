###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::RolesController < ApplicationController
  include ViewableEntities
  include EnforceHmisEnabled

  before_action :require_hmis_admin_access!
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
    @roles = role_scope.order(name: :asc)
    @per_page_js = ['role_manager']
  end

  def new
    @role = Hmis::Role.new
  end

  def edit
  end

  def update
    @role.update role_params
    respond_to do |format|
      format.html do
        respond_with(@role, location: hmis_admin_roles_path)
      end
      format.json do
        render(json: nil, status: :ok) if @role.errors.none?
        return
      end
    end
  end

  def batch_update
    begin
      Hmis::Role.transaction do
        batch_params[:role].each do |role_id, permissions|
          role_scope.find(role_id).update!(**permissions)
        end
      end
      flash[:notice] = 'All permissions saved'
    rescue Exception
      flash[:error] = 'Error saving permissions'
    end
    redirect_to(hmis_admin_roles_path)
  end

  def create
    @role = Hmis::Role.create(role_params)
    respond_with(@role, location: hmis_admin_roles_path)
  end

  def destroy
    @role.destroy
    redirect_to({ action: :index }, notice: 'Role deleted')
  end

  def title_for_show
    @role.name
  end
  alias title_for_edit title_for_show
  alias title_for_destroy title_for_show
  alias title_for_update title_for_show

  def title_for_index
    'Role List'
  end

  private def set_role
    @role = role_scope.find(params[:id].to_i)
  end

  private def role_scope
    Hmis::Role
  end

  private def role_params
    params.require(:role).
      permit(
        :name,
        Hmis::Role.permissions,
      )
  end

  def batch_params
    params.permit(role: [*Hmis::Role.permissions])
  end

  def flash_interpolation_options
    { resource_name: 'Role' }
  end
end
