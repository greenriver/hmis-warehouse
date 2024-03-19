###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::PitConcern
  extend ActiveSupport::Concern
  included do
    def available_report_versions
      {
        'FY 2024 (current)' => { slug: :fy2024, active: true },
        'FY 2023' => { slug: :fy2023, active: true },
        'FY 2022' => { slug: :fy2022, active: true },
      }.freeze
    end
    helper_method :available_report_versions

    def default_report_version
      :fy2024
    end

    private def filter_class
      ::Filters::HudFilterBase
    end

    private def possible_generator_classes
      {
        fy2022: HudPit::Generators::Pit::Fy2022::Generator,
        fy2023: HudPit::Generators::Pit::Fy2023::Generator,
        fy2024: HudPit::Generators::Pit::Fy2024::Generator,
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
      running_all_questions_hud_reports_pits_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
    end

    private def path_for_running_question
      running_hud_reports_pits_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
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

    def relevant_project_types
      HudUtility2024.homeless_project_types
    end
  end
end
