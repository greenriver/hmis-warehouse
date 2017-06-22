class AddExitView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Exit
    nt = Arel::Table.new :report_enrollments
    et = model.arel_table
    query = et.project( *et.engine.column_names.map(&:to_sym).map{ |c| et[c] }, nt[:id].as('enrollment_id'), nt[:client_id] ).
      join(nt).on( nt[:data_source_id].eq(et[:data_source_id]).and( nt[:ProjectEntryID].eq et[:ProjectEntryID] ) )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_exits, query
  end

  def down
    drop_view :report_exits
  end
end
