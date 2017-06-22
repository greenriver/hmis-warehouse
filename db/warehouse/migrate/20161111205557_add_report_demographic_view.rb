class AddReportDemographicView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Client
    ct  = model.arel_table
    rct = Arel::Table.new :report_clients
    wct = GrdaWarehouse::WarehouseClient.arel_table
    query = ct.
      project( *ct.engine.column_names.map(&:to_sym).map{ |c| ct[c] }, rct[:id].as('client_id') ).
      join(wct).on( wct[:source_id].eq ct[:id] ).
      join(rct).on( wct[:destination_id].eq rct[:id] )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_demographics, query
  end

  def down
    drop_view :report_demographics
  end
end
