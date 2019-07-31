###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Admin
  class AgenciesController < ApplicationController
    before_action :require_can_edit_users!
    before_action :set_agency, only: [:edit, :update, :destroy]

    def index
      @agencies = if params[:q].present?
        agency_scope.text_search(params[:q])
      else
        agency_scope
      end

      @agencies = @agencies.page(params[:page])
    end

    def new
      @agency = Agency.new
    end

    def create
      if @agency = Agency.create(agency_params)
        flash[:notice] = "#{@agency.name} was successfully added."
        redirect_to admin_agencies_path
      else
        render :new
      end
    end

    def edit

    end

    def update
      if @agency.update(agency_params)
        flash[:notice] = "#{@agency.name} was successfully updated."
        redirect_to admin_agencies_path
      else
        render :edit
      end
    end

    def destroy
      @agency.destroy
      flash[:notice] = "#{@agency.name} was successfully deleted."
      redirect_to admin_agencies_path
    end

    def set_agency
      @agency = agency_scope.find(params[:id].to_i)
    end

    def agency_params
      params.require(:agency).permit(:name)
    end

    def agency_scope
      Agency.
        includes(:users).
        preload(:users).
        order(:name)
    end
  end
end