###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper
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

    def available_report_versions
      {
        'FY 2024' => { slug: :fy2024, active: true },
      }.freeze
    end

    def default_report_version
      :fy2024
    end

    private def filter_class
      HopwaCaper::Filters::HopwaCaperFilter
    end

    private def path_for_question(question, report: nil, args: {})
      hud_reports_hopwa_caper_question_path({ hopwa_caper_id: report&.id || 0, id: question }.merge(args))
    end

    private def path_for_questions(question)
      hud_reports_hopwa_caper_questions_path(hopwa_caper_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_hopwa_caper_question_path(hopwa_caper_id: report&.id || 0, id: question)
    end

    private def path_for_report(report)
      hud_reports_hopwa_caper_path(report)
    end

    private def path_for_reports
      hud_reports_hopwa_capers_path
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_hopwa_caper_question_cell_path(hopwa_caper_id: report.id, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_hopwa_capers_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
    end

    private def path_for_running_question
      running_hud_reports_hopwa_capers_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
    end

    private def path_for_history(args = nil)
      history_hud_reports_hopwa_capers_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_hopwa_caper_path(report, args)
    end
    helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_hopwa_caper_path
    end
    helper_method :path_for_new

    private def set_pdf_export
      @pdf_export = HopwaCaper::DocumentExports::HopwaCaperExport.new
    end

    private def possible_generator_classes
      {
        fy2024: HopwaCaper::Generators::Fy2024::Generator,
      }
    end
  end
end
