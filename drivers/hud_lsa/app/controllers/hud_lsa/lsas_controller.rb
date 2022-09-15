###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa
  class LsasController < ::HudReports::BaseController
    before_action :filter
    before_action :generator, only: [:download]
    before_action :set_report, only: [:show, :destroy, :running, :download]
    before_action :set_reports, except: [:index, :running_all_questions]

    # Override default behavior, LSAs are different.
    def history
    end

    def available_report_versions
      {
        'FY 2022' => { slug: :fy2022, active: true },
      }.freeze
    end
    helper_method :available_report_versions

    def default_report_version
      :fy2022
    end

    private def filter_class
      ::Filters::HudFilterBase
    end

    private def zip_exporter
      ::HudReports::ZipExporter.new(@report, force_quotes: false, quote_empty: false)
    end

    private def possible_generator_classes
      {
        fy2022: HudLsa::Generators::Fy2022::Lsa,
      }
    end

    private def path_for_report(*options)
      hud_reports_lsa_path(options)
    end

    private def path_for_reports(*options)
      hud_reports_lsas_path(options)
    end

    private def path_for_question(question, report: nil, args: {})
      hud_reports_lsa_question_path({ lsa_id: report&.id || 0, id: question }.merge(args))
    end

    private def path_for_questions(question)
      hud_reports_lsa_questions_path(lsa_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_lsa_question_path(lsa_id: report&.id || 0, id: question)
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_lsa_question_cell_path(lsa_id: report&.id || 0, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_lsas_path(link_params.except('action', 'controller'))
    end

    private def path_for_running_question
      running_hud_reports_lsas_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_lsas_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_lsa_path(report, args)
    end
    helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_lsa_path
    end
    helper_method :path_for_new
  end
end
