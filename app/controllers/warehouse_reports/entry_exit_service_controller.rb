module WarehouseReports
  class EntryExitServiceController < WarehouseReportsController
    include WarehouseReportAuthorization
    def index
      # Clients who received services for one-day enrollments in housing related projects.
      # this is a translation of an original raw SQL query into Arel
      clients = GrdaWarehouse::Hud::Client
      ct = clients.arel_table
      pt = project_source.arel_table
      xt = GrdaWarehouse::Hud::Exit.arel_table
      st = GrdaWarehouse::Hud::Service.arel_table
      nt = GrdaWarehouse::Hud::Enrollment.arel_table
      wt = GrdaWarehouse::WarehouseClient.arel_table
      sql = clients.
        joins( :warehouse_client_source, enrollments: [ :project, :exit, :services ] ).
        where( pt[project_source.project_type_column].in project_source::RESIDENTIAL_PROJECT_TYPE_IDS ).
        where( xt[:ExitDate].eq st[:DateProvided] ).
        where( nt[:EntryDate].eq st[:DateProvided] ).
        select(
          st[:ProjectEntryID],
          nt[:EntryDate],
          st[:DateProvided],
          xt[:ExitDate],
          xt[:PersonalID],
          xt[:data_source_id],
          ct[:FirstName],
          ct[:LastName],
          wt[:destination_id],
          nt[:ProjectID],
          pt[:ProjectName],
          pt[project_source.project_type_column].as('project_type'),
          st[:RecordType]
        ).distinct.to_sql
      @enrollments = if GrdaWarehouse::Hud::Service.all.engine.postgres?
        result = GrdaWarehouseBase.connection.select_all(sql)
        result.map do |row|
          Hash.new.tap do |hash|
            result.columns.each_with_index.map do |name, idx| 
              hash[name.to_s] = result.send(:column_type, name).type_cast_from_database(row[name])
            end
          end
        end
      else
        GrdaWarehouseBase.connection.raw_connection.execute(sql).each( as: :hash )
      end
      respond_to :html, :xlsx
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/entry_exit_service')
    end
  end
end
