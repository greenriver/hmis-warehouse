class AddHealthAndDvView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::HealthAndDv
    nt  = Arel::Table.new :report_enrollments
    dt  = Arel::Table.new :report_demographics
    hdt = model.arel_table 
    query = hdt.project( *hdt.engine.column_names.map(&:to_sym).map{ |c| hdt[c] }, nt[:id].as('enrollment_id'), dt[:id].as('demographic_id'), dt[:client_id] ).
      join(nt).on( nt[:data_source_id].eq(hdt[:data_source_id]).and( nt[:ProjectEntryID].eq hdt[:ProjectEntryID] ) ).
      join(dt).on( dt[:data_source_id].eq(hdt[:data_source_id]).and( dt[:PersonalID].eq hdt[:PersonalID] ) )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_health_and_dvs, query
  end

  def down
    drop_view :report_health_and_dvs
  end
end
