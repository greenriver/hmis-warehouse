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

    def new
      @default_coc = GrdaWarehouse::Config.default_site_coc_codes&.first
      report
    end

    def create
      if @filter.valid?
        @report = report_class.from_filter(@filter, report_name, build_for_questions: generator.questions.keys)
        @report.state = 'Waiting'
        @report.question_names = @report.class.questions.keys
        @report.save!
        HudLsa::RunReportJob.perform_later(@report.id)

        # @report = report_source.from_filter(@filter, report_name, build_for_questions: generator.questions.keys)
        # generator.new(report: @report).queue
        redirect_to(path_for_history(filter: @filter.to_h))
      else
        render :new
      end
    end

    private def report
      @report ||= report_class.new(options: { user_id: current_user.id })
    end

    private def report_class
      @report_class ||= active_version
    end
    helper_method :report_class

    private def missing_data
      @missing_data ||= report.missing_data(current_user)
    end
    helper_method :missing_data

    private def active_version
      possible_generator_classes[default_report_version]
    end

    private def filter
      year = if Date.current.month >= 10
        Date.current.year
      else
        Date.current.year - 1
      end
      # Some sane defaults, using the previous report if available
      @filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false)
      if filter_params.blank?
        prior_report = generator.find_report(current_user)
        options = prior_report&.options
        site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
        if options.present?
          @filter.start = options['start'].presence || Date.new(year - 1, 10, 1)
          @filter.end = options['end'].presence || Date.new(year, 9, 30)
          @filter.coc_code = options['coc_codes'].presence || site_coc_codes
          @filter.update(options.with_indifferent_access)
          @filter.report_version = options['report_version'].presence || default_report_version
        else
          @filter.start = Date.new(year - 1, 10, 1)
          @filter.end = Date.new(year, 9, 30)
          @filter.coc_code = site_coc_codes
          @filter.report_version = default_report_version
        end
      end
      # Override with params if set
      @filter.update(filter_params) if filter_params.present?
    end

    private def report_name
      active_version.title
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
      ::HudLsa::Filters::LsaFilter
    end

    # private def zip_exporter
    #   ::HudReports::ZipExporter.new(@report, force_quotes: false, quote_empty: false)
    # end

    private def possible_generator_classes
      {
        fy2022: HudLsa::Generators::Fy2022::Lsa,
      }
    end

    private def path_for_report(*options)
      hud_reports_lsa_path(options)
    end

    # private def path_for_reports(*options)
    #   hud_reports_lsas_path(options)
    # end

    # private def path_for_question(question, report: nil, args: {})
    #   hud_reports_lsa_question_path({ lsa_id: report&.id || 0, id: question }.merge(args))
    # end

    # private def path_for_questions(question)
    #   hud_reports_lsa_questions_path(lsa_id: 0, question: question)
    # end

    # private def path_for_question_result(question, report: nil)
    #   result_hud_reports_lsa_question_path(lsa_id: report&.id || 0, id: question)
    # end

    # private def path_for_cell(report:, question:, cell_label:, table:)
    #   hud_reports_lsa_question_cell_path(lsa_id: report&.id || 0, question_id: question, id: cell_label, table: table)
    # end

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

    # def path_for_report_download(report, args)
    #   download_hud_reports_lsa_path(report, args)
    # end
    # helper_method :path_for_report_download

    private def path_for_new
      new_hud_reports_lsa_path
    end
    helper_method :path_for_new
  end
end
