module WarehouseReports
  class EntryExitServiceController < ApplicationController
    before_action :require_can_view_reports!
    def index
      # Clients who received services for one-day enrollments in housing related projects.
      # this is a translation of an original raw SQL query into Arel
      clients = GrdaWarehouse::Hud::Client
      ct = clients.arel_table
      pt = GrdaWarehouse::Hud::Project.arel_table
      xt = GrdaWarehouse::Hud::Exit.arel_table
      st = GrdaWarehouse::Hud::Service.arel_table
      nt = GrdaWarehouse::Hud::Enrollment.arel_table
      wt = GrdaWarehouse::WarehouseClient.arel_table
      sql = clients.
        joins( :warehouse_client_source, enrollments: [ :project, :exit, :services ] ).
        where( pt[:ProjectType].in GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS ).
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
          pt[:ProjectType],
          st[:RecordType]
        ).distinct.to_sql
      @enrollments = GrdaWarehouseBase.connection.raw_connection.execute(sql).each(as: :hash)
      respond_to :html, :xlsx
    end
  end
end