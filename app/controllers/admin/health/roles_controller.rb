###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class RolesController < Admin::RolesController
    include HealthAuthorization
    include HealthPatient
    before_action :require_has_administrative_access_to_health!

    def index
      @roles = role_scope.order(name: :asc).
        page(params[:page].to_i).
        per(50)
    end

    def update
      @role.update role_params
      respond_to do |format|
        format.html do
          # respond_with(@role, location: admin_health_roles_path)
          flash[:notice] = "#{@role.name} updated."
          redirect_to(admin_health_roles_path)
          return
        end
        format.json do
          render(json: nil, status: :ok) if @role.errors.none?
          return
        end
      end
    end

    private

    def role_scope
      Role.health
    end

    def role_params
      params.require(:role).
        permit(
          :name,
          Role.health_permissions,
        )
    end
  end
end
