###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class UsersController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_assign_or_view_users_to_clients!
    before_action :require_can_assign_users_to_clients!, only: [:update, :destroy, :create, :edit]
    before_action :set_client
    before_action :set_user, only: [:edit, :update, :destroy]
    after_action :log_client

    def index
      @user = user_source.new
      @user_clients = @client.user_clients.preload(:user).to_a || []
    end

    def create
      @user = user_source.new(user_client_params.merge(client_id: params[:client_id].to_i))
      begin
        @user.save!
      rescue Exception => e
        @user_clients = @client.user_clients.preload(:user).to_a || []
        flash[:error] = e.message
        render action: :index
        return
      end
      flash[:notice] = 'Relationship added.'
      redirect_to action: :index
    end

    def update
      @user.update(user_client_params)
    end

    def destroy
      if @user.destroy
        flash[:notice] = 'Relationship removed.'
      else
        flash[:error] = "Unable to remove the #{@user.relationship} relationship."
      end
      redirect_to action: :index
    end

    def user_client_params
      params.require(:grda_warehouse_user_client).permit(
        :user_id,
        :client_id,
        :relationship,
        :client_notifications,
        :confidential,
        :start_date,
        :end_date,
      )
    end

    def user_source
      GrdaWarehouse::UserClient
    end

    def user_scope
      user_source
    end

    def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    def set_user
      @user = user_scope.find(params[:id].to_i)
    end

    protected def title_for_show
      "#{@client.name} - Relationships"
    end
  end
end
