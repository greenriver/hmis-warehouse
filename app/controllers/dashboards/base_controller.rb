###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Dashboards
  class BaseController < ApplicationController
    include ArelHelper
    include Rails.application.routes.url_helpers
    include WarehouseReportAuthorization

    CACHE_EXPIRY = Rails.env.production? ? 8.hours : 20.seconds

    before_action :available_months
    before_action :set_chosen_months
    before_action :set_report_months
    before_action :set_filter

    def index
      @report = active_report_class.new(
        user: current_user,
        months: @report_months,
        filter: @filter,
      )

      respond_to do |format|
        format.html do
          @html = true
          render 'dashboards/base/index'
        end
        format.xlsx do
          require_can_access_some_version_of_clients!
          @enrollments = @report.enrolled_clients
          @clients = GrdaWarehouse::Hud::Client.where(
            id: @enrollments.distinct.pluck(:client_id),
          ).index_by(&:id)
          @projects = GrdaWarehouse::Hud::Project.where(
            id: @enrollments.distinct.pluck(:project_id),
          ).pluck(:id, :ProjectName).to_h
          @organizations = GrdaWarehouse::Hud::Organization.where(
            id: @enrollments.distinct.pluck(:organization_id),
          ).pluck(:id, :OrganizationName).to_h
        end
        format.pdf do
          render_pdf!
        end
      end
    end

    def section
      @report = active_report_class.new(
        user: current_user,
        months: @report_months,
        filter: @filter,
      )
      section = allowed_sections.detect do |m|
        m == params.require(:partial).underscore
      end

      raise 'Rollup not in allowlist' unless section.present?

      section = 'dashboards/base/' + section
      render partial: section, layout: false if request.xhr?
    end

    private def allowed_sections
      [
        'overview',
        'censuses',
        'entry',
        'exit',
      ].freeze
    end
    helper_method :allowed_sections

    def pdf
      render_pdf!
    end

    private def render_pdf!
      @pdf = true
      file_name = "#{@report.sub_population_title} Dashboard"
      send_data dashboard_pdf(file_name), filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    private def dashboard_pdf(_file_name)
      grover_options = {
        display_url: root_url,
        displayHeaderFooter: true,
        headerTemplate: '<h2>Header</h2>',
        footerTemplate: '<h6 class="text-center">Footer</h6>',
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        margin: {
          top: '.5in',
          bottom: '.5in',
          left: '.4in',
          right: '.4in',
        },
        debug: {
          # headless: false,
          # devtools: true
        },
      }

      grover_options[:executablePath] = ENV['CHROMIUM_PATH'] if ENV['CHROMIUM_PATH']

      html = render_to_string('dashboards/base/index')
      Grover.new(html, grover_options).to_pdf
    end

    def describe_computations
      path = 'app/views/dashboards/base/README.md'
      description = File.read(path)
      markdown = Redcarpet::Markdown.new(::TranslatedHtml)
      markdown.render(description)
    end
    helper_method :describe_computations

    private def can_see_client_details?
      @can_see_client_details ||= if @project_ids == []
        current_user.can_access_some_version_of_clients?
      else
        true
      end
    end
    helper_method :can_see_client_details?

    def report_params
      return {} if params[:filters].blank?

      params.require(:filters).
        permit(
          :start,
          :end,
          :limit_to_vispdat,
          :hoh_only,
          races: [],
          ethnicities: [],
          genders: [],
          organization_ids: [],
          project_ids: [],
          project_type_codes: [],
          age_ranges: [],
          coc_codes: [],
        )
    end
    helper_method :report_params

    def available_months
      @available_months ||= active_report_class.available_months
    end

    # to_i.to_s to ensure end result is an integer
    def set_chosen_months
      @start_month = begin
                       JSON.parse(report_params[:start_month]).map(&:to_i).to_s
                     rescue StandardError
                       [6.months.ago.year, 6.months.ago.month].to_s
                     end
      @end_month = begin
                     JSON.parse(report_params[:end_month]).map(&:to_i).to_s
                   rescue StandardError
                     [1.months.ago.year, 1.months.ago.month].to_s
                   end
    end

    def set_report_months
      all_months_array = @available_months.keys
      start_index = all_months_array.index(JSON.parse(@start_month))
      end_index = all_months_array.index(JSON.parse(@end_month)) || 0
      @report_months = begin
                         all_months_array[end_index..start_index]
                       rescue StandardError
                         []
                       end
    end

    def set_start_date
      (year, month) = @report_months.last
      @start_date = begin
                      Date.new(year, month, 1)
                    rescue StandardError
                      Date.current
                    end
    end

    def set_end_date
      (year, month) = @report_months.first
      @end_date = begin
                    Date.new(year, month, -1)
                  rescue StandardError
                    Date.current
                  end
    end

    def set_filter
      @filter = ::Filters::FilterBase.new(user_id: current_user.id)
      @filter.set_from_params(report_params) if report_params.present?
    end

    def support_filter
      @filter.for_params[:filters]
    end
    helper_method :support_filter
  end
end
