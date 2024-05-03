###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport
  class SpmsController < BaseController
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
          exporter = ::HudReports::CsvExporter.new(@report, 'csv', external_row_label: true)
          send_data(exporter.export_as_string, filename: csv_filename)
        end
      end
    end

    private def csv_filename
      "#{generator.file_prefix} - #{DateTime.current.to_fs(:db)}.csv"
    end
  end
end
