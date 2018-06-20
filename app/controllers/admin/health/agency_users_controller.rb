module Admin::Health
  class AgencyUsersController < HealthController
    before_action :require_has_administartive_access_to_health!
    before_action :require_can_administer_health!
    before_action :load_user, only: [:new, :edit]
    before_action :load_agencies, only: [:new, :edit]

    def new
      @agency_user = Health::AgencyUser.new(user: @user)
      @form_url = admin_health_user_agency_users_path(@user)
      render layout: false
    end

    def edit
      @agency_user = Health::AgencyUser.find(params[:id])
      @form_url = admin_health_user_agency_user_path(@user, @agency_user)
      render layout: false
    end

    def create
      @agency_user = Health::AgencyUser.new(agency_user_params)
      if @agency_user.save
        flash[:notice] = "#{@agency_user.user.name_with_email} is now a manager for #{@agency_user.agency.name}."
      else
        flash[:error] = "An error occurred, please try again."
      end
      redirect_to admin_health_users_path
    end

    def update
      @agency_user = Health::AgencyUser.find(params[:id])
      if @agency_user.update_attributes(agency_user_params)
        flash[:notice] = "#{@agency_user.user.name_with_email} is now a manager for #{@agency_user.agency.name}."
      else
        flash[:error] = "An error occurred, please try again."
      end
      redirect_to admin_health_users_path
    end

    private

    def agency_user_params
      params.require(:health_agency_user).permit(
        :user_id,
        :agency_id
      )
    end

    def load_agencies
      @agencies = Health::Agency.all
    end

    def load_user
      @user = User.find(params[:user_id])
    end

  end
end