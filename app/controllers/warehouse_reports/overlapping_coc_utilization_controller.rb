###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OverlappingCoCUtilizationController < ApplicationController
    include WarehouseReportAuthorization
    RELEVANT_COC_STATE = ENV.fetch('RELEVANT_COC_STATE') do
      GrdaWarehouse::Shape::CoC.order(Arel.sql('random()')).limit(1).pluck(:st)
    rescue StandardError
      'UNKNOWN'
    end

    private def state_coc_shapes
      GrdaWarehouse::Shape::CoC.where(
        st: RELEVANT_COC_STATE,
      )
    end

    private def coc_shapes_with_data
      state_coc_shapes.where(
        cocnum: GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode),
      )
    end

    private def overlap_by_coc_code
      GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode).map do |coc_code|
        [coc_code, rand(255)]
      end.to_h
    end

    private def map_shapes
      GrdaWarehouse::Shape.geo_collection_hash(
        state_coc_shapes,
      )
    end
    helper_method :map_shapes

    private def map_data
      {}.tap do |data|
        map_shapes[:features].each do |feature|
          overlap_by_coc_code.each do |coc_code, value|
            data[feature.dig(:properties, :id).to_s] = value if feature.dig(:properties, :cocnum) == coc_code
          end
        end
      end
    end
    helper_method :map_data

    def index
      @end_date = (Date.current - 1.years).end_of_year
      @start_date = @end_date.beginning_of_year
      @cocs = coc_shapes_with_data
      @shapes = map_shapes
    end

    def details
      @coc1 = GrdaWarehouse::Shape::CoC.find_by(id: params.require(:coc1))
      @coc2 = GrdaWarehouse::Shape::CoC.find_by(id: params.require(:coc2))
      attr = {
        coc_code_1: @coc1.cocnum,
        coc_code_2: @coc2.cocnum,
        start_date: Date.parse(params.require(:start_date)),
        end_date: Date.parse(params.require(:end_date)),
      }
      cache_key = [current_user.id, @report.class.name, attr]

      @report = WarehouseReport::OverlappingCocByProjectType.new(attr)
      @details = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        @report.details_hash
      end
    end

    private def report_params
      params.require(:compare).permit(
        :coc1,
        :coc2,
        :start_date,
        :end_date,
      )
    end
    helper_method :report_params

    def overlap
      @coc1 = GrdaWarehouse::Shape::CoC.find(report_params.require(:coc1))
      @coc2 = GrdaWarehouse::Shape::CoC.find(report_params.require(:coc2))
      start_date = report_params.require(:start_date)
      end_date = report_params.require(:end_date)
      p_type_report = WarehouseReport::OverlappingCocByProjectType.new(
        coc_code_1: @coc1.cocnum,
        coc_code_2: @coc2.cocnum,
        start_date: start_date,
        end_date: end_date,
      )
      project_types = p_type_report.for_chart
      funding_sources = WarehouseReport::OverlappingCocByFundingSource.new(
        coc_code_1: @coc1.cocnum,
        coc_code_2: @coc2.cocnum,
        start_date: start_date,
        end_date: end_date,
      ).for_chart

      locals = {
        start_date: params.dig(:compare, :start_date),
        end_date: params.dig(:compare, :end_date),
        project_types: project_types,
        funding_sources: funding_sources,
        overlapping_client_count: p_type_report.all_overlapping_clients,
      }
      html = render_to_string partial: 'overlap', locals: locals
      render json: { map: map_data, html: html }
    end
  end
end
