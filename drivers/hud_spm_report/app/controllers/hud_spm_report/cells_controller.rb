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
      set_common_variables

      @search_term = nil
      # Only show search if the model supports it
      @searchable = model_searchable?

      respond_to do |format|
        format.html { render_html_response(base_scope) }
        format.xlsx { render_xlsx_response }
      end
    end

    def search
      set_common_variables

      search_query = GrdaWarehouse::ClientSearchQuery.find_by(id: params[:query_id])
      return handle_invalid_query('Search query not found') if search_query.nil?

      search_query.touch

      @search_term = search_query.query_params[:q].to_s

      filtered_scope = if (@searchable = model_searchable?)
        base_scope.model.search_clients(base_scope, @search_term)
      else
        base_scope
      end

      respond_to do |format|
        format.html { render_html_response(filtered_scope) }
      end
    end

    private

    def set_common_variables
      params.require(report_param_name)
      set_report

      @question = generator.valid_question_number params.require(:measure_id)
      @cell = @report.valid_cell_name params.require(:id)
      @table = params.require(:table)
      @name = "#{generator.file_prefix} #{@question} #{@cell}"
      @headers = generator.column_headings(@question)
    end

    def base_scope
      @base_scope ||= generator.client_scope(@question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct
    end

    def model_searchable?
      base_scope.model.respond_to?(:searchable?) && base_scope.model.searchable?
    end

    def render_html_response(scope)
      @total_count = base_scope.count
      @filtered_count = scope.count

      # Paginate and preload associations to avoid N+1 queries
      @pagy, paginated_clients = pagy(scope, items: 100)
      @clients = paginated_clients.preload(client: [:data_source, :source_clients])

      render :show
    end

    def render_xlsx_response
      # For Excel downloads, load all records
      @clients = base_scope.preload(client: [:data_source, :source_clients])
      @headers = @headers.transform_keys(&:to_s).except(*generator.pii_columns) unless GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
      headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
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
