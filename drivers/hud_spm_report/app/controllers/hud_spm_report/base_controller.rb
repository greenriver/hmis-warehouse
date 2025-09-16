###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  class BaseController < ::HudReports::BaseController
    before_action :filter

    private def relevant_project_types
      HudUtility2026.spm_project_type_numbers
    end

    def cell_value(cell, path)
      if path.to_s.include?('.')
        path_parts = path.to_s.split('.')
        path_parts.each do |part|
          cell = cell.send(part) unless cell.nil?
        end
        cell
      else
        cell[path]
      end
    end
    helper_method :cell_value

    private def filter_class
      ::Filters::HudFilterBase
    end

    private def path_for_question(question, report: nil, args: {})
      hud_reports_spm_measure_path({ spm_id: report&.id || 0, id: question }.merge(args))
    end

    private def path_for_questions(question)
      hud_reports_spm_measures_path(spm_id: 0, question: question)
    end

    private def path_for_question_result(question, report: nil)
      result_hud_reports_spm_measure_path(spm_id: report&.to_param || 0, id: question)
    end

    private def path_for_report(report)
      hud_reports_spm_path(report)
    end

    private def path_for_reports
      hud_reports_spms_path
    end

    private def path_for_cell(report:, question:, cell_label:, table:)
      hud_reports_spm_measure_cell_path(spm_id: report&.to_param || 0, measure_id: question, id: cell_label, table: table)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_spms_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
    end

    private def path_for_running_question
      running_hud_reports_spms_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
    end

    private def path_for_history(args = nil)
      history_hud_reports_spms_path(args)
    end
    helper_method :path_for_history

    private def set_pdf_export
      @pdf_export = HudSpmReport::DocumentExports::HudSpmReportExport.new
    end

    def path_for_report_download(report, args)
      download_hud_reports_spm_path(report, args)
    end
    helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_spm_path
    end
    helper_method :path_for_new

    def available_report_versions
      # We only want to show the versions that have a matching generator class
      super.select { |_, v| possible_generator_classes.keys.include?(v[:slug]) }
    end
    helper_method :available_report_versions

    private def possible_generator_classes
      {
        fy2020: HudSpmReport::Generators::Fy2020::Generator,
        fy2023: HudSpmReport::Generators::Fy2023::Generator,
        fy2024: HudSpmReport::Generators::Fy2024::Generator,
        fy2026: HudSpmReport::Generators::Fy2026::Generator,
      }
    end
  end
end
