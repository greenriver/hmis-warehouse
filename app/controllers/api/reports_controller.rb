###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api
  class ReportsController < ApplicationController
    def favorite
      @report = GrdaWarehouse::WarehouseReports::ReportDefinition.find(params[:id])

      is_favorited = Favorite.find_by(user: current_user, entity_id: @report.id, entity_type: 'GrdaWarehouse::WarehouseReports::ReportDefinition').present?
      Rails.logger.warn ">>>>is_favorited #{is_favorited}"

      type = params[:type]
      if type == 'favorite'
        current_user.favorite_reports << @report
        Rails.logger.warn '>>>>Added to favorites'
      elsif type == 'unfavorite'
        current_user.favorite_reports.delete(@report)
        Rails.logger.warn '>>>>Removed from favorites'

      else
        # Type missing, nothing happens
        Rails.logger.warn '>>>>Type missing'
      end
    end
  end
end
