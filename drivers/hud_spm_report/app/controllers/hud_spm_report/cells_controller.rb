###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  class CellsController < HudSpmReport::BaseController
    private def report_param_name
      :spm_id
    end

    def show
      params.require(report_param_name)

      set_report

      @question = generator.valid_question_number params.require(:measure_id)
      @cell = @report.valid_cell_name params.require(:id)
      @table = params.require(:table) # valid_table_name is too strict for the SPM table names
      @name = "#{generator.file_prefix} #{@question} #{@cell}"

      @headers = generator.column_headings(@question)

      base_scope = generator.client_scope(@question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct

      @search_term = nil
      # Only show search if the model supports it
      @searchable = base_scope.model.respond_to?(:searchable?) && base_scope.model.searchable?(base_scope)
      filtered_scope = base_scope

      respond_to do |format|
        format.html do
          # Get counts for display
          @total_count = base_scope.count
          @filtered_count = @total_count

          # Paginate and preload associations to avoid N+1 queries
          @pagy, paginated_clients = pagy(filtered_scope, items: 100)
          @clients = paginated_clients.preload(client: [:data_source, :source_clients])
        end
        format.xlsx do
          # For Excel downloads, load all records
          @clients = filtered_scope.preload(client: [:data_source, :source_clients])
          @headers = @headers.transform_keys(&:to_s).except(*generator.pii_columns) unless GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    def search
      params.require(report_param_name)

      set_report

      @question = generator.valid_question_number params.require(:measure_id)
      @cell = @report.valid_cell_name params.require(:id)
      @table = params.require(:table)

      search_query = GrdaWarehouse::ClientSearchQuery.find_by(id: params[:query_id])
      return handle_invalid_query('Search query not found') if search_query.nil?

      search_query.touch

      @name = "#{generator.file_prefix} #{@question} #{@cell}"
      @headers = generator.column_headings(@question)

      base_scope = generator.client_scope(@question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct

      @search_term = search_query.query_params[:q].to_s

      if base_scope.model.respond_to?(:searchable?) && base_scope.model.searchable?
        filtered_scope = base_scope.model.search_clients(base_scope, @search_term)
        @searchable = true
      else
        filtered_scope = base_scope
        @searchable = false
      end

      respond_to do |format|
        format.html do
          @total_count = base_scope.count
          @filtered_count = filtered_scope.count

          @pagy, paginated_clients = pagy(filtered_scope, items: 100)
          @clients = paginated_clients.preload(client: [:data_source, :source_clients])

          render :show
        end
        format.xlsx do
          @clients = filtered_scope.preload(client: [:data_source, :source_clients])
          @headers = @headers.transform_keys(&:to_s).except(*generator.pii_columns) unless GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    private def handle_invalid_query(message)
      flash[:error] = message
      redirect_to hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: @question,
        id: @cell,
        table: @table,
      )
    end
  end
end
