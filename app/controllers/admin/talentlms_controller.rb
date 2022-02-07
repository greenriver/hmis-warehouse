###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TalentlmsController < ApplicationController
    before_action :require_can_manage_config!

    def index
      @config = Talentlms::Config.first_or_initialize
    end

    def create
      @config = Talentlms::Config.first_or_initialize
      @config.assign_attributes(config_params)
      if config.valid?
        @config.save
        redirect_to action: :index
      else
        render :index
      end
    end

    def config_params
      params.require(:talentlms_config).permit(
        :subdomain,
        :api_key,
        :courseid,
      )
    end
  end
end
