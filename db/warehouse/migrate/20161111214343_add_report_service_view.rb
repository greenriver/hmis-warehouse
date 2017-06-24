class AddReportServiceView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Service
    dt = Arel::Table.new :report_demographics
    st = model.arel_table
    query = st.project( *st.engine.column_names.map(&:to_sym).map{ |c| st[c] }, dt[:id].as('demographic_id'), dt[:client_id] ).
      join(dt).on( dt[:data_source_id].eq(st[:data_source_id]).and( dt[:PersonalID].eq st[:PersonalID] ) )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_services, query
  end

  def down
    drop_view :report_services
  end
end
