###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class WarehouseAlertsController < ApplicationController
    before_action :require_can_edit_warehouse_alerts!, except: [:show]
    before_action :load_alert_and_form_url_for_edit, only: [:edit, :update]
    before_action :load_alert_and_form_url_for_new, only: [:new, :destroy]

    def index
      if warehouse_alert_scope.exists?
        @alert = warehouse_alert_scope.first
        @form_url = admin_warehouse_alert_path(@alert)
        redirect_to edit_admin_warehouse_alert_path(@alert)
      else
        load_alert_and_form_url_for_new
        redirect_to action: :new
      end
    end

    def show
      @alert = warehouse_alert_source.find params[:id]
    end

    def new
    end

    def create
      @alert = warehouse_alert_source.new(warehouse_alert_params)
      if @alert.save
        redirect_to(admin_warehouse_alerts_path, notice: 'Alert created')
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    def edit
    end

    def update
      if @alert.update(warehouse_alert_params)
        redirect_to({ action: :index }, notice: 'Alert updated')
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    def destroy
      @alert.destroy
      redirect_to(admin_warehouse_alerts_path, notice: 'Warehouse alert deleted')
    end

    def load_alert_and_form_url_for_edit
      @alert = warehouse_alert_scope.find params[:id]
      @form_url = admin_warehouse_alert_path(@alert)
    end

    def load_alert_and_form_url_for_new
      @alert = warehouse_alert_source.new
      @form_url = admin_warehouse_alerts_path
    end

    def warehouse_alert_scope
      warehouse_alert_source.all
    end

    def warehouse_alert_source
      WarehouseAlert
    end

    private

    def warehouse_alert_params
      params.require(:warehouse_alert).permit(:html).merge(user_id: current_user.id)
    end
  end
end
