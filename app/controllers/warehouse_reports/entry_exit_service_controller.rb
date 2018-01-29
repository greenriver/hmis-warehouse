module WarehouseReports
  class EntryExitServiceController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    def index
      # Clients who received services for one-day enrollments in housing related projects.
      # this is a translation of an original raw SQL query into Arel
      clients = GrdaWarehouse::Hud::Client
      sql = clients.
        joins( :warehouse_client_source, enrollments: [ :project, :exit, :services ] ).
        where( p_t[project_source.project_type_column].in project_source::RESIDENTIAL_PROJECT_TYPE_IDS ).
        where( ex_t[:ExitDate].eq s_t[:DateProvided] ).
        where( e_t[:EntryDate].eq s_t[:DateProvided] ).
        select(
          s_t[:ProjectEntryID],
          e_t[:EntryDate],
          s_t[:DateProvided],
          ex_t[:ExitDate],
          ex_t[:PersonalID],
          ex_t[:data_source_id],
          c_t[:FirstName],
          c_t[:LastName],
          wc_t[:destination_id],
          e_t[:ProjectID],
          p_t[:ProjectName],
          p_t[project_source.project_type_column].as('project_type'),
          s_t[:RecordType]
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

  end
end
