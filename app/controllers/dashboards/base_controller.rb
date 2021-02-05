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
    before_action :set_project_types
    before_action :set_project_and_organization_ids
    before_action :set_start_date
    before_action :set_end_date
    before_action :set_limit_to_vispdat
    before_action :set_limit_to_heads_of_household
    before_action :set_age_ranges
    before_action :set_cocs

    def index
      @report = active_report_class.new(
        months: @report_months,
        organization_ids: @organization_ids,
        project_ids: @project_ids,
        project_types: @project_type_codes,
        filter: {
          vispdat: @limit_to_vispdat,
          heads_of_household: @heads_of_household,
          age_ranges: @age_ranges,
        },
      )

      respond_to do |format|
        format.html do
          @html = true
          render 'dashboards/base/index'
        end
        format.xlsx do
          require_can_view_clients!
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
        months: @report_months,
        organization_ids: @organization_ids,
        project_ids: @project_ids,
        project_types: @project_type_codes,
        filter: {
          vispdat: @limit_to_vispdat,
          heads_of_household: @heads_of_household,
          age_ranges: @age_ranges,
          coc_codes: @coc_codes,
        },
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
        current_user.can_view_clients?
      else
        true
      end
    end
    helper_method :can_see_client_details?

    def report_params
      return {} if params[:choose_report].blank?

      params.require(:choose_report).
        permit(
          :start_month,
          :end_month,
          :limit_to_vispdat,
          :heads_of_household,
          organization_ids: [],
          project_ids: [],
          project_types: [],
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

    def set_project_and_organization_ids
      @organization_ids = begin
        report_params[:organization_ids].map(&:presence).compact.map(&:to_i)
      rescue StandardError
        []
      end
      @project_ids = begin
        report_params[:project_ids].map(&:presence).compact.map(&:to_i)
      rescue StandardError
        []
      end
    end

    def set_project_types
      @project_type_codes = GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.keys
      return if params.try(:[], :choose_report).try(:[], :project_types).blank?

      @project_type_codes = params.try(:[], :choose_report).try(:[], :project_types).
        select(&:present?).
        map(&:to_sym).
        select { |m| m.in?(GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.keys) }
    end

    def vispdat_limits
      {
        'All clients' => :all_clients,
        'Only clients with VI-SPDATs' => :with_vispdat,
        'Only clients without VI-SPDATs' => :without_vispdat,
      }
    end
    helper_method :vispdat_limits

    def set_limit_to_vispdat
      # Whitelist values
      @limit_to_vispdat = begin
        vispdat_limits.values.detect do |v|
          v == report_params[:limit_to_vispdat].to_sym
        end
      rescue StandardError
        :all_clients
      end
    end

    def set_limit_to_heads_of_household
      @heads_of_household = report_params[:heads_of_household].to_s == '1'
    end

    def set_age_ranges
      @age_ranges = report_params[:age_ranges]&.reject(&:blank?)&.map(&:to_sym)
    end

    def set_cocs
      @coc_codes = report_params[:coc_codes]&.reject(&:blank?)
    end
  end
end
