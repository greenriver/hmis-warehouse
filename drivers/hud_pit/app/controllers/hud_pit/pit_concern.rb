###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::PitConcern
  extend ActiveSupport::Concern
  included do
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

    private def possible_generator_classes
      {
        fy2022: HudPit::Generators::Pit::Fy2022::Generator,
      }
    end

    private def path_for_report(*options)
      hud_reports_pit_path(options)
    end

    private def path_for_reports(*options)
      hud_reports_pits_path(options)
    end

    private def path_for_question(question, report: nil, args: {})
      hud_reports_pit_question_path({ pit_id: report&.id || 0, id: question }.merge(args))
    end

    private def path_for_questions(question)
      hud_reports_pit_questions_path(pit_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_pit_question_path(pit_id: report&.id || 0, id: question)
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_pit_question_cell_path(pit_id: report&.id || 0, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_pits_path(link_params.except('action', 'controller'))
    end

    private def path_for_running_question
      running_hud_reports_pits_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_pits_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_pit_path(report, args)
    end
    helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_pit_path
    end
    helper_method :path_for_new
  end
end
