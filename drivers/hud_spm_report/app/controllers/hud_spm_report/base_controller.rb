###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport
  class BaseController < ::HudReports::BaseController
    before_action :filter

    def filter_params
      return {} unless params[:filter]

      filter_p = params.require(:filter).permit(@filter.known_params)
      filter_p[:user_id] = current_user.id

      filter_p
    end

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
        else
          @filter.start = Date.new(year - 1, 10, 1)
          @filter.end = Date.new(year, 9, 30)
        end
      end
      # Override with params if set
      @filter.set_from_params(filter_params) if filter_params.present?
    end

    private def filter_class
      generator.filter_class
    end

    private def generator
      @generator ||= HudSpmReport::Generators::Fy2020::Generator
    end
    helper_method :generator

    private def path_for_question(question, report: nil)
      hud_reports_spm_measure_path(spm_id: report&.to_param || 0, id: question)
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
  end
end
