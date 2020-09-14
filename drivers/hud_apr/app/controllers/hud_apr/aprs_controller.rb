###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr
  class AprsController < BaseController
    before_action -> { set_generator(param_name: :generator) }, except: [:index]
    before_action -> { set_report(param_name: :id) }, only: [:show, :edit, :destroy]
    before_action :set_reports, except: [:index]

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
        coc_code: options['coc_code'] || GrdaWarehouse::Config.get(:site_coc_codes),
        project_ids: options['project_ids']&.map(&:to_i),
      )
    end

    def set_reports
      titles = generators.map(&:title)
      @reports = report_source.where(report_name: titles).order(created_at: :desc)
    end

    def report_urls
      @report_urls ||= Rails.application.config.hud_reports.map { |title, helper| [title, public_send(helper)] }
    end
  end
end
