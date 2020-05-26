###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class AprsController < ApplicationController
    before_action :set_generator, except: [:index]
    def index
      @tab_content_reports = Report.active.order(weight: :asc, type: :desc).map(&:report_group_name).uniq
      @report_urls = report_urls
      @generators = generators
    end

    def show
      respond_to do |format|
        format.html {}
        format.zip do
          report = nil # TODO
          exporter = HudReports::ZipExporter.new(report)
          date = Date.current.strftime('%Y-%m-%d')
          send_data exporter.export!, filename: "apr-#{date}.zip"
        end
      end
    end

    def edit
    end

    def update
      gen = @generator.new(filter_options)
      gen.run!
      redirect_to hud_reports_aprs_path
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
      @generator_id = params[:id].to_i
      @generator = generators[@generator_id]
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
  end
end
