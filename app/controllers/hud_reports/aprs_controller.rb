###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class AprsController < ApplicationController
    before_action :set_generator, except: [:index]
    before_action :set_reports, except: [:index]
    before_action :set_report, only: [:show, :edit, :destroy]

    def index
      @tab_content_reports = Report.active.order(weight: :asc, type: :desc).map(&:report_group_name).uniq
      @report_urls = report_urls
      @generators = generators
    end

    def show
      respond_to do |format|
        format.html do
          @questions = @generator.questions.keys
          @contents = @report&.completed_questions
          @options = options_struct
        end
        format.zip do
          exporter = HudReports::ZipExporter.new(@report)
          date = Date.current.strftime('%Y-%m-%d')
          send_data exporter.export!, filename: "apr-#{date}.zip"
        end
      end
    end

    def edit
      @options = options_struct
    end

    def update
      gen = @generator.new(filter_options)
      gen.run!
      redirect_to hud_reports_apr_path(0, generator: @generator_id)
    end

    def destroy
      @report.destroy
      redirect_to hud_reports_apr_path(0, generator: @generator_id)
    end

    def options_struct
      options = @report&.options || {}
      @options = OpenStruct.new(
        start_date: options['start_date']&.to_date || Date.current.last_month.beginning_of_month.last_year,
        end_date: options['end_date']&.to_date || Date.current.last_month.end_of_month,
        coc_code: options['coc_code'],
        project_ids: options['project_ids']&.map(&:to_i),
      )
    end

    def filter_options
      filter = params.require(:filter).
        permit(
          :start_date,
          :end_date,
          :coc_code,
          project_ids: [],
        )
      filter[:user_id] = current_user.id
      filter[:project_ids] = filter[:project_ids].reject(&:blank?).map(&:to_i)
      filter
    end

    def set_generator
      @generator_id = params[:generator].to_i
      @generator = generators[@generator_id]
    end

    def set_report
      report_id = params[:id].to_i
      # APR 0 is the most recent report for the current user
      if report_id.zero?
        @report = @generator.find_report(current_user)
      else
        @report = report_source.find(report_id)
      end
    end

    def set_reports
      titles = generators.map(&:title)
      @reports = report_source.where(report_name: titles).order(created_at: :desc)
    end

    def generators
      [
        ReportGenerators::Apr::Fy2020::Generator,
      ]
    end

    def report_urls
      [
        ['Annual Performance Report', hud_reports_aprs_path],
      ]
    end

    def report_source
      HudReports::ReportInstance
    end
  end
end
