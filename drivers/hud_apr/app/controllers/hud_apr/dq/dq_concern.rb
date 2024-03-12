###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Dq::DqConcern
  extend ActiveSupport::Concern

  included do
    private def path_for_question(question, report: nil, args: {})
      hud_reports_dq_question_path({ dq_id: report&.id || 0, id: question }.merge(args))
    end

    private def path_for_questions(question)
      hud_reports_dq_questions_path(dq_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_dq_question_path(dq_id: report&.id || 0, id: question)
    end

    private def path_for_report(*options)
      hud_reports_dq_path(options)
    end

    private def path_for_reports(*options)
      hud_reports_dqs_path(options)
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_dq_question_cell_path(dq_id: report&.id || 0, question_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_dqs_path(link_params.except('action', 'controller'))
    end

    private def path_for_running_question
      running_hud_reports_dqs_path(link_params.except('action', 'controller'))
    end

    private def path_for_history(args = nil)
      history_hud_reports_dqs_path(args)
    end
    helper_method :path_for_history

    def path_for_report_download(report, args)
      download_hud_reports_dq_path(report, args)
    end
    helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_dq_path
    end
    helper_method :path_for_new

    private def set_pdf_export
      @pdf_export = HudApr::DocumentExports::HudDqExport.new
    end

    def history
      report_version = params[:filter]&.try(:[], :report_version)

      redirect_to history_hud_reports_past_dqs_path(params.permit!) and return if report_version.present? && past_report_versions.include?(report_version.to_sym)

      # Fall through to the normal history logic
      super
    end

    def generator
      @generator ||= possible_generator_classes[report_version]
    end

    private def set_question
      @question = generator.valid_question_number(params[:question] || params[:id])
    end

    def available_report_versions
      {
        'FY 2020' => { slug: :fy2020, active: false },
        'FY 2022' => { slug: :fy2022, active: false },
        'FY 2024 (current)' => { slug: :fy2024, active: true },
      }.freeze
    end

    private def possible_generator_classes
      {
        fy2024: HudApr::Generators::Dq::Fy2024::Generator,
      }
    end

    private def past_report_versions
      [:fy2020, :fy2022]
    end
  end
end
