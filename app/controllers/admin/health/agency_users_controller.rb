###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class AgencyUsersController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_administer_health!
    before_action :load_user, only: [:new, :edit]
    before_action :load_agencies, only: [:new, :edit]

    def new
      # @agency_user = Health::AgencyUser.new(user: @user)
      # @form_url = admin_health_user_agency_users_path(@user)
      # render layout: false
      render_agency_user_modal
    end

    # def edit
    #   # @agency_user = Health::AgencyUser.find(params[:id])
    #   # @form_url = admin_health_user_agency_user_path(@user, @agency_user)
    #   # render layout: false
    #   render_agency_user_modal
    # end

    def create
      # @agency_user = Health::AgencyUser.new(agency_user_params)
      # if @agency_user.save
      #   flash[:notice] = "#{@agency_user.user.name_with_email} is now a manager for #{@agency_user.agency.name}."
      # else
      #   flash[:error] = "An error occurred, please try again."
      # end
      # redirect_to admin_health_users_path
      @agency_user_saver = Health::AgencyUserSaver.new(agency_users_params)
      @agency_user_saver.save
      respond_with @agency_user_saver, location: admin_health_users_path
    end

    # def update
    #   # @agency_user = Health::AgencyUser.find(params[:id])
    #   # if @agency_user.update(agency_user_params)
    #   #   flash[:notice] = "#{@agency_user.user.name_with_email} is now a manager for #{@agency_user.agency.name}."
    #   # else
    #   #   flash[:error] = "An error occurred, please try again."
    #   # end
    #   # redirect_to admin_health_users_path
    # end

    private

    def render_agency_user_modal
      @form_url = admin_health_user_agency_users_path(@user)
      @agency_user_saver = Health::AgencyUserSaver.new(user_id: @user.id, agency_ids: @agency_users.map(&:agency_id))
      render layout: !request.xhr?
    end

    def agency_users_params
      params.require(:agency_users).permit(
        :user_id,
        agency_ids: [],
      )
    end

    def load_agencies
      @agencies = Health::Agency.all
    end

    def load_user
      @user = User.find(params[:user_id])
      @agency_users = @user.agency_users
    end
  end
end
