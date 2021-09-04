###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport
  class BaseController < ::HudReports::BaseController
    before_action :filter

    def filter_params
      return {} unless params[:filter]

      filter_p = params.require(:filter).
        permit(
          :start,
          :end,
          :report_version,
          coc_codes: [],
          project_ids: [],
          project_type_codes: [],
          project_group_ids: [],
          data_source_ids: [],
        )
      filter_p[:user_id] = current_user.id

      filter_p
    end
    helper_method :available_report_versions

    # NOTE filter differs slightly from the base version
    private def filter
      year = if Date.current.month >= 10
        Date.current.year
      else
        Date.current.year - 1
      end
      # Some sane defaults, using the previous report if available
      @filter = filter_class.new(user_id: current_user.id)
      if filter_params.blank?
        prior_report = generator.find_report(current_user)
        options = prior_report&.options
        site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
        if options.present?
          @filter.start = options['start'].presence || Date.new(year - 1, 10, 1)
          @filter.end = options['end'].presence || Date.new(year, 9, 30)
          @filter.coc_codes = options['coc_codes'].presence || site_coc_codes
          @filter.project_ids = options['project_ids']
          @filter.project_type_codes = options['project_type_codes']
          @filter.project_group_ids = options['project_group_ids']
          @filter.data_source_ids = options['data_source_ids']
          @filter.report_version = options['report_version'].presence || default_report_version
        else
          @filter.start = Date.new(year - 1, 10, 1)
          @filter.end = Date.new(year, 9, 30)
          @filter.report_version = default_report_version
        end
      end
      # Override with params if set
      @filter.set_from_params(filter_params) if filter_params.present?
    end

    def available_report_versions
      {
        'FY 2020' => :fy2020,
        'FY 2021' => :fy2021,
      }.freeze
    end

    def default_report_version
      :fy2020
    end

    private def filter_class
      HudPathReport::Filters::PathFilter
    end

    def generator
      @generator ||= begin
        case filter_params[:report_version]&.to_sym || @filter&.report_version || default_report_version
        when :fy2020
          HudPathReport::Generators::Fy2020::Generator
        when :fy2021
          HudPathReport::Generators::Fy2021::Generator
        end
      end
    end
    helper_method :generator

    private def path_for_question(question, report: nil)
      hud_reports_path_question_path(path_id: report&.id || 0, id: question)
    end

    private def path_for_questions(question)
      hud_reports_path_questions_path(path_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_path_question_path(path_id: report&.id || 0, id: question)
    end

    private def path_for_report(report)
      hud_reports_path_path(report)
    end

    private def path_for_reports
      hud_reports_paths_path
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_path_question_cell_path(path_id: report.id, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_paths_path
    end

    private def path_for_running_question
      running_hud_reports_paths_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_paths_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_path_path(report, args)
    end
    helper_method :path_for_report_download

    private def set_pdf_export
      @pdf_export = HudPathReport::DocumentExports::HudPathReportExport.new
    end

    private def possible_generator_classes
      [
        HudPathReport::Generators::Fy2020::Generator,
        HudPathReport::Generators::Fy2021::Generator,
      ]
    end
  end
end
