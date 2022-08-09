###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OverlappingCoCUtilizationController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    CACHE_VERSION = '1aa'.freeze
    CACHE_LIFETIME = 30.minutes.freeze

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
        cocnum: available_cocs,
      )
    end

    private def available_cocs
      project_coc_scope.available_coc_codes
    end

    private def project_coc_scope
      GrdaWarehouse::Hud::ProjectCoc.viewable_by(current_user)
    end

    private def overlap_by_coc_code
      ::WarehouseReport::OverlappingCoc.new(
        start_date: filters.start_date,
        end_date: filters.end_date,
        coc_code: filters.coc1.cocnum,
      ).results
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
      @cocs = state_coc_shapes.sort_by(&:number_and_name)
      @shapes = map_shapes
    end

    def details
      @report = load_overlapping_coc_by_project_type_report(project_type: params.dig(:project_type))
      @details = Rails.cache.fetch(
        @report.cache_key.merge(user_id: current_user.id, view: :details_hash, rev: CACHE_VERSION),
        expires_in: CACHE_LIFETIME,
      ) do
        @report.details_hash
      end
    rescue WarehouseReport::OverlappingCocByProjectType::Error => e
      bad_request(e.message)
    end

    def clients
      @report = load_overlapping_coc_by_project_type_report(project_type: params.dig(:project_type))
      @details = Rails.cache.fetch(
        @report.cache_key.merge(user_id: current_user.id, view: :limited_details_hash, rev: CACHE_VERSION),
        expires_in: CACHE_LIFETIME,
      ) do
        @report.limited_details_hash(current_user)
      end
      layout = if request.xhr?
        'content_only'
      else
        'application'
      end
      render clients_warehouse_reports_overlapping_coc_utilization_index_path, layout: layout
    rescue WarehouseReport::OverlappingCocByProjectType::Error => e
      bad_request(e.message)
    end

    private def load_overlapping_coc_by_project_type_report(project_type: nil)
      WarehouseReport::OverlappingCocByProjectType.new(
        coc_code_1: filters.coc1&.cocnum,
        coc_code_2: filters.coc2&.cocnum,
        start_date: filters.start_date,
        end_date: filters.end_date,
        project_type: project_type,
      )
    end

    private def filters
      @filters ||= OverlappingCoCUtilizationForm.new(report_params)
    end
    helper_method :filters

    private def report_params
      return {} if params[:compare].blank?

      params.require(:compare).permit(
        :coc1_id,
        :coc2_id,
        :start_date,
        :end_date,
      )
    end

    def overlap
      coc1 = filters.coc1
      coc2 = filters.coc2

      payload = {
        coc1_id: coc1&.id,
        coc2_id: coc2&.id,
        coc1: coc1.number_and_name,
        coc2: coc2&.number_and_name,
        map_title: "#{coc1.number_and_name} shared clients with the following CoCs",
        title: 'Overview of Shared Client by Project Type and CoC',
        subtitle: "Served between #{filters.start_date} - #{filters.end_date}",
        error: nil,
      }
      payload[:map] = map_data
      payload[:html] = if coc1 && coc2
        report = load_overlapping_coc_by_project_type_report
        Rails.cache.fetch(
          report.cache_key.merge(user_id: current_user.id, view: :overlap, rev: CACHE_VERSION),
          expires_in: CACHE_LIFETIME,
        ) do
          render_to_string(partial: 'overlap', locals: { report: report })
        end
      end

      if coc1 && coc2
        payload[:subtitle] = "Served in both #{filters.coc1.number_and_name} and #{filters.coc2.number_and_name}, between #{filters.start_date} - #{filters.end_date}"
      else
        payload[:subtitle] = "Served in #{filters.coc1.number_and_name}, between #{filters.start_date} - #{filters.end_date}"
      end
    rescue WarehouseReport::OverlappingCocByProjectType::Error, WarehouseReport::OverlappingCoc::Error => e
      payload[:error] = e.message
    ensure
      render json: payload
    end

    class OverlappingCoCUtilizationForm
      attr_accessor :coc1_id, :coc2_id, :start_date, :end_date

      def coc1
        coc1_id ? (@coc1 ||= GrdaWarehouse::Shape::CoC.find(coc1_id)) : nil
      end

      def coc2
        coc2_id ? (@coc2 ||= GrdaWarehouse::Shape::CoC.find(coc2_id)) : nil
      end

      def to_params
        {
          coc1_id: coc1_id,
          coc2_id: coc2_id,
          start_date: start_date,
          end_date: end_date,
        }
      end

      def initialize(attr)
        assign_attributes(attr)
      end

      def assign_attributes(attr)
        self.end_date = parse_date(attr[:end_date]) || (Date.current - 1.years).end_of_year
        self.start_date = parse_date(attr[:start_date]) || end_date.beginning_of_year
        self.coc1_id = attr[:coc1_id].presence
        self.coc2_id = attr[:coc2_id].presence
      end

      private def parse_date(str)
        Date.parse(str)
      rescue StandardError
        nil
      end
    end
  end
end
