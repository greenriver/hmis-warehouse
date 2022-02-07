###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Dashboards
  class BaseController < ApplicationController
    include ArelHelper
    include Rails.application.routes.url_helpers
    include WarehouseReportAuthorization

    CACHE_EXPIRY = Rails.env.production? ? 8.hours : 20.seconds

    def index
      @report = active_report_class.new(
        user: current_user,
        filter: filter,
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
        filter: filter,
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
      if params[:filters].blank?
        return {
          start: default_start_date,
          end: default_end_date,
          project_type_codes: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPE_CODES,
        }
      end

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
          project_group_ids: [],
          project_type_codes: [],
          age_ranges: [],
          coc_codes: [],
        )
    end
    helper_method :report_params

    def available_months
      @available_months ||= active_report_class.available_months
    end

    def default_end_date
      # Last day of the previous month
      available_months.first&.prev_day || 1.months.ago.end_of_month
    end

    def default_start_date
      available_months.select { |k| k < default_end_date && k > default_end_date - 7.months }.min || default_end_date.beginning_of_month
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: current_user.id, enforce_one_year_range: false)
        f.set_from_params(report_params)
        f
      end
    end
    helper_method :filter

    def support_filter
      filter.for_params[:filters].merge(sub_population: @report.sub_population)
    end
    helper_method :support_filter
  end
end
