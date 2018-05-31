module Admin::Health
  class UsersController < HealthController
    before_action :require_has_administartive_access_to_health!
    before_action :require_can_administer_health!
    
    def index
      @users = User.all.
        order(last_name: :asc, first_name: :asc).
        page(params[:page].to_i).per(50)
    end

    def update
      error = false
      users_params.each do |_, user_info|
        begin
          ::User.transaction do
            id = user_info[:id].to_i
            user = ::User.find(id)
            roles = user_info[:roles]
            available_role_ids = Role.health.pluck(:id)
            enabled_role_ids = []
            if roles.present?
              enabled_role_ids = roles.keys.map(&:to_i) & available_role_ids
            end
            disabled_role_ids = available_role_ids - enabled_role_ids
            current_roles = user.roles
            new_roles = current_roles + Role.where(id: enabled_role_ids) - Role.where(id: disabled_role_ids)
            user.roles = new_roles            
          end
        rescue ActiveRecord::ActiveRecordError => e
          flash[:error] = 'Unable to update roles'
          error = true
          render action: :index
        end   
      end
      flash[:notice] = 'Role assignments updated'
      redirect_to action: :index if ! error
    end

    def users_params
      params.require(:users)
    end
  end
end