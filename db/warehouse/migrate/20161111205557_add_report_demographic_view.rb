class AddReportDemographicView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Client
    gh_client_table        = model.arel_table
    report_client_table    = Arel::Table.new :report_clients
    warehouse_client_table = GrdaWarehouse::WarehouseClient.arel_table
    query = ct.
      project(
        *gh_client_table.engine.column_names.map(&:to_sym).map{ |c| gh_client_table[c] }, # all the client columns
        report_client_table[:id].as('client_id')                                          # also a fake foreign key mapping to clients report
      ).
      join(warehouse_client_table).on(
        warehouse_client_table[:source_id].eq gh_client_table[:id]                        # where this client is a source
      ).
      join(report_client_table).on(
        warehouse_client_table[:destination_id].eq report_client_table[:id]               # and the corresponding client report represents the destination
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_demographics, query
  end

  def down
    drop_view :report_demographics
  end
end
