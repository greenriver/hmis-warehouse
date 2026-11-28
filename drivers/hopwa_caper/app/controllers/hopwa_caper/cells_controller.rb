###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper
  class CellsController < HopwaCaper::QuestionsController
    before_action :set_report
    before_action :set_question
    before_action :enforce_question_completed, only: :show
    before_action :set_cell_records, only: :show
    before_action :enforce_hiv_drilldown_access, only: :show

    def show
      @name = "#{generator.file_prefix} #{@question} #{@cell}"
      current_user.policy_context.preload_client_dependencies(
        @enrollments.map(&:destination_client_id_for_pii) + @services.map(&:destination_client_id_for_pii),
      )
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    private def set_cell_records
      @cell = @report.valid_cell_name(params[:id])
      @enrollments = @report.hopwa_caper_enrollments.
        preload(enrollment: [:project, :client, :data_source]).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell))
      @services = @report.hopwa_caper_services.
        preload(enrollment: { enrollment: [:project, :client, :data_source] }).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell))
    end

    private def enforce_question_completed
      universe = @report.existing_universe(@question)
      @table = @report.valid_table_name(params[:table])
      return if universe&.status == 'Completed' && Array(universe.metadata&.dig('tables')).include?(@table)

      redirect_to(
        path_for_question_result(@question, report: @report),
        alert: 'This drilldown is not available.',
      )
    end

    private def enforce_hiv_drilldown_access
      access = HopwaCaper::HivDrilldownAccess.new(
        user: current_user,
        enrollments: @enrollments,
        services: @services,
        mode: request.format.html? ? :browse : :download,
      )
      return if access.allowed?

      redirect_to(
        path_for_question_result(@question, report: @report),
        alert: 'You do not have permission to view HIV/AIDS drilldown data.',
      )
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
