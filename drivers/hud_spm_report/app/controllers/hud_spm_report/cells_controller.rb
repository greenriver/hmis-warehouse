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
      filtered_scope = apply_search_filter(base_scope, @search_term)

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

    private def apply_search_filter(scope, search_term)
      return scope if search_term.blank?

      # Build search conditions across common searchable fields
      # Search is case-insensitive using ILIKE
      search_pattern = "%#{sanitize_sql_like(search_term)}%"

      # Determine the model class to know how to search
      model_class = scope.model

      if model_class == HudSpmReport::Fy2026::Episode || model_class == HudSpmReport::Fy2026::Return
        # Episode and Return need to search through their enrollments relationship
        # Join to SpmEnrollment (via enrollment_links) and search there
        enrollment_table_name = HudSpmReport::Fy2026::SpmEnrollment.table_name

        conditions = [
          "#{enrollment_table_name}.first_name ILIKE :search",
          "#{enrollment_table_name}.last_name ILIKE :search",
          "#{enrollment_table_name}.personal_id ILIKE :search",
          "CAST(#{enrollment_table_name}.id AS TEXT) ILIKE :search",
          "CAST(#{enrollment_table_name}.client_id AS TEXT) ILIKE :search",
        ]

        # Join to enrollments and filter
        scope.joins(:enrollments).where(conditions.join(' OR '), search: search_pattern).distinct
      else
        # For SpmEnrollment or other models, search directly on the model
        table_name = scope.table_name
        conditions = [
          "CAST(#{table_name}.id AS TEXT) ILIKE :search",
          "CAST(#{table_name}.client_id AS TEXT) ILIKE :search",
        ]

        # Add commonly searchable fields if they exist on the model
        searchable_columns = %w[first_name last_name personal_id]
        searchable_columns.each do |col|
          conditions << "#{table_name}.#{col} ILIKE :search" if scope.column_names.include?(col)
        end

        scope.where(conditions.join(' OR '), search: search_pattern)
      end
    end

    private def sanitize_sql_like(string)
      string.gsub(/[\\%_]/) { |m| "\\#{m}" }
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
