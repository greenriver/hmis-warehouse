###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api
  class ReportsController < ApplicationController
    def favorite
      currently_favorited = current_user.favorite_reports.exists?(params[:id])
      return if currently_favorited

      Favorite.create(user_id: current_user.id, entity_id: params[:id].to_i, entity_type: 'GrdaWarehouse::WarehouseReports::ReportDefinition')
    end

    def unfavorite
      current_user.favorite_reports.where(id: params[:id].to_i).destroy_all
    end
  end
end
