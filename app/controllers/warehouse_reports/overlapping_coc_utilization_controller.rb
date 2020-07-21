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

    Form = Struct.new(:coc1, :coc2, :start_date, :end_date, keyword_init: true)
    def index
      @end_date = (Date.current - 1.years).end_of_year
      @start_date = @end_date.beginning_of_year
      @cocs = state_coc_shapes
      @shapes = map_shapes
      @compare = Form.new(**report_params.to_h.symbolize_keys)
    end

    def details
      @report = WarehouseReport::OverlappingCocByProjectType.new(
        coc_code_1: GrdaWarehouse::Shape::CoC.find(params.require(:coc1)).cocnum,
        coc_code_2: GrdaWarehouse::Shape::CoC.find(params.require(:coc2)).cocnum,
        start_date: Date.parse(params.require(:start_date)),
        end_date: Date.parse(params.require(:end_date)),
        project_type: params.dig(:project_type),
      )
      @details = Rails.cache.fetch(
        @report.cache_key.merge(user_id: current_user.id, view: :details_hash),
        expires_in: 30.minutes,
      ) do
        @report.details_hash
      end
    rescue WarehouseReport::OverlappingCocByProjectType::Error => e
      bad_request(e.message)
    end

    private def report_params
      return {} if params[:compare].blank?

      params.require(:compare).permit(
        :coc1,
        :coc2,
        :start_date,
        :end_date,
      )
    end
    helper_method :report_params

    def overlap
      coc1 = GrdaWarehouse::Shape::CoC.find(report_params.require(:coc1))
      coc2 = if (coc2_id = report_params.dig(:coc2)).present?
        GrdaWarehouse::Shape::CoC.find(coc2_id)
      end

      report_args = {
        coc_code_1: coc1.cocnum,
        coc_code_2: coc2&.cocnum,
        start_date: Date.parse(report_params.require(:start_date)),
        end_date: Date.parse(report_params.require(:end_date)),
      }
      report_html = if coc2
        begin
          report = WarehouseReport::OverlappingCocByProjectType.new(**report_args)
          Rails.cache.fetch(
            report.cache_key.merge(user_id: current_user.id, view: :overlap),
            expires_in: 30.minutes,
          ) do
            render_to_string(partial: 'overlap', locals: { report: report })
          end
        rescue WarehouseReport::OverlappingCocByProjectType::Error => e
          e.message
        end
      end

      render json: {
        coc1: coc1.number_and_name,
        coc2: coc2&.number_and_name,
        map_title: "#{coc1.number_and_name} shared clients with the following CoCs",
        map: map_data,
        html: report_html,
      }
    end
  end
end
