###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HomelessSummaryReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :require_can_access_some_version_of_clients!, only: [:details]
    before_action :set_report, only: [:show, :destroy, :details]
    before_action :set_variants, only: [:show, :details]
    before_action :set_m1_fields, only: [:show, :details]
    before_action :set_m2_fields, only: [:show]
    before_action :set_m7_fields, only: [:show, :details]

    def index
      @reports = report_scope.ordered.
        page(params[:page]).per(25)
      @report = report_class.new(user_id: current_user.id)
      # Make sure the form will work
      filters
    end

    def show
      @measures = {
        'Measure 1': @m1_fields.keys,
        'Measure 2': @m2_fields,
        'Measure 7': @m7_fields,
      }
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
      )
      @report.filter = @filter
      @report.save
      # TODO: Now we need to figure out how to define the job. I think it's by modifying the report class, probably ultimately the run_and_save! method. Yes.
      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      # Make sure the form will work
      filters
      respond_with(@report, location: homeless_summary_report_warehouse_reports_reports_path)
    end

    def destroy
      @report.destroy
      respond_with(@report, location: homeless_summary_report_warehouse_reports_reports_path)
    end

    def details
      @variant = details_params['variant'] || 'all_persons'
      @cell = "spm_#{details_params['cell']}" || 'spm_m1a_es_sh_days'
      @cell_name = @cell.humanize.split(' ')[1..].join(' ')
      if details_params['cell'].start_with?('m1')
        @measure = 'Measure 1'
        @data_cells = @m1_fields.keys
      elsif details_params['cell'].start_with?('m2')
        @measure = 'Measure 2'
        @data_cells = ['m2_reentry_days']
      elsif details_params['cell'].start_with?('m7')
        @measure = 'Measure 2'
        @data_cells = @m7_fields
      end
      @detail_clients = @report.clients.send(@variant).send(@cell)
      @spm_id = @detail_clients.first.send("spm_#{@variant}")
    end

    def details_params
      params.permit(
        :variant,
        :cell,
      ).delete_if do |key, value|
        key == 'variant' && report_class.report_variants.keys.exclude?(value.to_sym)
      end.delete_if do |key, value|
        key == 'cell' && (report_class.spm_fields.keys + [
          :m2_reentry_0_to_180_days,
          :m2_reentry_181_to_365_days,
          :m2_reentry_366_to_730_days,
          :m7a1_c2,
          :m7a1_c3,
          :m7a1_c4,
          :m7b1_c2,
          :m7b1_c3,
          :m7b2_c2,
          :m7b2_c3,
        ]).exclude?(value.to_sym)
      end
    end
    helper_method :details_params

    private def set_report
      @report = report_class.find(params[:id].to_i)
    end

    private def set_variants
      @variants = ::HomelessSummaryReport::Report.report_variants
    end

    private def set_m1_fields
      @m1_fields = report_class.spm_fields.filter { |f| f.start_with?('m1') }
    end

    private def set_m2_fields
      @m2_fields = [
        :m2_reentry_days,
        :m2_reentry_0_to_180_days,
        :m2_reentry_181_to_365_days,
        :m2_reentry_366_to_730_days,
      ]
    end

    private def set_m7_fields
      @m7_fields = report_class.spm_fields.keys.filter { |f| f.start_with?('m7') }.concat(
        [
          :m7a1_c2,
          :m7a1_c3,
          :m7a1_c4,
          :m7b1_c2,
          :m7b1_c3,
          :m7b2_c2,
          :m7b2_c3,
        ],
      )
    end

    private def report_scope
      report_class.visible_to(current_user)
    end

    private def report_class
      HomelessSummaryReport::Report
    end

    def filter_params
      # TODO: I think we can ratchet this back. Needs review
      # because some of the sub-reports require coc_codes, we need to make sure those are set, even
      # if we can't set them manually (non-multi-coc installation)
      site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
      default_options = {
        comparison_pattern: :prior_year,
        sub_population: :clients,
        coc_codes: site_coc_codes,
      }
      return { filters: default_options } unless params[:filters].present?

      filters = params.permit(filters: @filter.known_params)
      filters[:coc_codes] ||= site_coc_codes
      filters
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end
  end
end
