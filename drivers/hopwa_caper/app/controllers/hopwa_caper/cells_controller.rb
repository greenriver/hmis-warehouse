###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper
  class CellsController < HopwaCaper::QuestionsController
    include ::HudReports::ArtifactAwareCells

    before_action :set_report
    before_action :set_question

    def show
      @cell = @report.valid_cell_name(params[:id])
      @table = @report.valid_table_name(params[:table])

      # Load enrollments
      @enrollments = if @report.artifacts_stored?
        load_hopwa_caper_enrollments_from_s3(@table)
      else
        @report.hopwa_caper_enrollments.
          preload(enrollment: :project).
          joins(hud_reports_universe_members: { report_cell: :report_instance }).
          merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell))
      end

      # Load services
      @services = if @report.artifacts_stored?
        load_hopwa_caper_services_from_s3(@table)
      else
        @report.hopwa_caper_services.
          preload(enrollment: { enrollment: :project }).
          joins(hud_reports_universe_members: { report_cell: :report_instance }).
          merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell))
      end

      @name = "#{generator.file_prefix} #{@question} #{@cell}"
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    private

    def load_hopwa_caper_enrollments_from_s3(table)
      return @report.hopwa_caper_enrollments.none unless @cell

      # @cell may be coming in as a string (e.g. "B3") or a ReportCell object
      cell_name = @cell.is_a?(String) ? @cell : @cell.cell_name
      report_cell = @report.report_cells.find_by(cell_name: cell_name, question: table)

      return @report.hopwa_caper_enrollments.none unless report_cell

      service = ::HudReports::S3ArtifactService.new(@report)
      csv_data = service.retrieve_universe_members(question: table)
      return @report.hopwa_caper_enrollments.none unless csv_data

      cell_members = csv_data.select { |row| row['report_cell_id'].to_i == report_cell.id }
      enrollment_ids = cell_members.map { |row| row['universe_membership_id'].to_i }.compact.uniq

      @report.hopwa_caper_enrollments.where(id: enrollment_ids).preload(enrollment: :project)
    end

    def load_hopwa_caper_services_from_s3(table)
      return @report.hopwa_caper_services.none unless @cell

      # If @cell is a string (cell name), find the actual ReportCell object
      report_cell = if @cell.is_a?(String)
        @report.report_cells.find_by(cell_name: @cell, question: table)
      else
        @cell.question == table ? @cell : @report.report_cells.find_by(cell_name: @cell.cell_name, question: table)
      end

      return @report.hopwa_caper_services.none unless report_cell

      service = ::HudReports::S3ArtifactService.new(@report)
      csv_data = service.retrieve_universe_members(question: table)
      return @report.hopwa_caper_services.none unless csv_data

      cell_members = csv_data.select { |row| row['report_cell_id'].to_i == report_cell.id }
      service_ids = cell_members.map { |row| row['universe_membership_id'].to_i }.compact.uniq

      @report.hopwa_caper_services.where(id: service_ids).preload(enrollment: { enrollment: :project })
    end

    def formatted_cell(cell)
      return cell.to_json if cell.is_a?(Array) || cell.is_a?(Hash)

      cell
    end
    helper_method :formatted_cell

    def count_dates(date_array)
      date_array.sort.tally.map { |k, v| "#{k} (#{v})" }.join(', ')
    end
    helper_method :count_dates
  end
end
