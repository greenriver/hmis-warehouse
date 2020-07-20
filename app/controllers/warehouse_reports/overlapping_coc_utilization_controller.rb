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

    private def bad_request(msg_html)
      render html: "<h1>Invalid request</h1><p>#{msg_html}</p>".html_safe
    end

    private def map_data
      {}.tap do |data|
        map_shapes[:features].each do |feature|
          overlap_by_coc_code.each do |coc_code, value|
            data[feature.dig(:properties, :id).to_s] = value if feature.dig(:properties, :cocnum) == coc_code
          end
        end
      end
    end

    def index
      @end_date = (Date.current - 1.years).end_of_year
      @start_date = @end_date.beginning_of_year
      @cocs = coc_shapes_with_data
      @shapes = map_shapes
    end

    def details
      report_args = {
        coc_code_1: GrdaWarehouse::Shape::CoC.find(params.require(:coc1)).cocnum,
        coc_code_2: GrdaWarehouse::Shape::CoC.find(params.require(:coc2)).cocnum,
        start_date: Date.parse(params.require(:start_date)),
        end_date: Date.parse(params.require(:end_date)),
      }
      report_cache_key = [current_user.id, @report.class.name, Date.current, report_args]
      @report = WarehouseReport::OverlappingCocByProjectType.new(**report_args)
      @details = Rails.cache.fetch(report_cache_key, expires_in: 5.minutes) do
        @report.details_hash
      end
    rescue WarehouseReport::OverlappingCocByProjectType::Error => e
      bad_request(e.message)
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
      report_args = {
        coc_code_1: GrdaWarehouse::Shape::CoC.find(report_params.require(:coc1)).cocnum,
        coc_code_2: GrdaWarehouse::Shape::CoC.find(report_params.require(:coc2)).cocnum,
        start_date: Date.parse(report_params.require(:start_date)),
        end_date: Date.parse(report_params.require(:end_date)),
      }

      report = WarehouseReport::OverlappingCocByProjectType.new(**report_args)
      render json: { map: map_data, html: render_to_string(partial: 'overlap', locals: { report: report }) }
    rescue WarehouseReport::OverlappingCocByProjectType::Error => e
      render json: { map: map_data, html: e.message }
    end
  end
end
