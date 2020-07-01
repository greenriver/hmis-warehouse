###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OverlappingCoCUtilizationController < ApplicationController
    RELEVANT_COC_STATE = ENV.fetch('RELEVANT_COC_STATE') do
      GrdaWarehouse::Shape::CoC.order('random()').limit(1).pluck(:st)
    rescue StandardError
      'UNKNOWN'
    end

    def index
      @cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      @shapes = GrdaWarehouse::Shape.geo_collection_hash(@cocs)
    end
  end
end
