###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class RolesController < ApplicationController
    before_action :require_can_edit_roles!
    before_action :set_role, only: [:edit, :update, :destroy]

    require 'active_support'
    require 'active_support/core_ext/string/inflections'

    def index
      @roles = role_scope.order(name: :asc)
    end

    def new
      @role = Role.new
    end

    def edit
      @users = User.joins(:roles).merge(Role.where(id: @role.id))
    end

    def update
      @role.update role_params
      respond_to do |format|
        format.html do
          respond_with(@role, location: admin_roles_path)
        end
        format.json do
          render(json: nil, status: :ok) if @role.errors.none?
          return
        end
      end
    end

    def create
      @role = Role.create(role_params)
      respond_with(@role, location: admin_roles_path)
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

    private

    def set_role
      @role = role_scope.find(params[:id].to_i)
    end

    def role_scope
      Role.editable
    end

    def role_params
      params.require(:role).
        permit(
          :name,
          Role.permissions(exclude_health: true),
        )
    end
  end
end
