###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport
  class SpmsController < BaseController
    before_action :generator, only: [:download]
    before_action :set_report, only: [:show, :destroy, :running, :download]
    before_action :set_reports, except: [:index, :running_all_questions]
    before_action :set_pdf_export, only: [:show, :download]

    def show
      respond_to do |format|
        format.html do
          @show_recent = params[:id].to_i.positive?
          @questions = generator.questions.keys
          @contents = @report&.completed_questions
          @path_for_running = path_for_running_question
        end
        format.csv do
          exporter = HudSpmReport::Fy2023::HdxUploadCsvExporter.new(report: @report, generator: generator)
          send_data(exporter.csv_export, filename: exporter.csv_filename)
        end
      end
    end
  end
end
