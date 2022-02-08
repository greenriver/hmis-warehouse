###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class ConsentLimitsController < ApplicationController
    before_action :require_can_edit_users!
    before_action :set_consent_limit, only: [:show, :edit, :update, :destroy]

    respond_to :html

    def index
      @consent_limits = ConsentLimit.all
      respond_with(@consent_limits)
    end

    def new
      @consent_limit = ConsentLimit.new
      respond_with(@consent_limit)
    end

    def edit
    end

    def create
      @consent_limit = ConsentLimit.create(consent_limit_params)
      respond_with(@consent_limit, location: admin_consent_limits_path)
    end

    def update
      @consent_limit.update(consent_limit_params)
      respond_with(@consent_limit, location: admin_consent_limits_path)
    end

    def destroy
      @consent_limit.destroy
      respond_with(@consent_limit, location: admin_consent_limits_path)
    end

    private

    def set_consent_limit
      @consent_limit = ConsentLimit.find(params[:id])
    end

    def consent_limit_params
      params.require(:consent_limit).permit(:name, :description, :color, :deleted_at)
    end
  end
end
