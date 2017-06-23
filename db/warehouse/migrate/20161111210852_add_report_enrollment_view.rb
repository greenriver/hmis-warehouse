class AddReportEnrollmentView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Enrollment
    dt = Arel::Table.new :report_demographics
    et = model.arel_table
    query = et.
      project( *et.engine.column_names.map(&:to_sym).map{ |c| et[c] }, dt[:id].as('demographic_id'), dt[:client_id] ).
      outer_join(dt).on( dt[:data_source_id].eq( et[:data_source_id]).and( dt[:PersonalID].eq et[:PersonalID] ) )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_enrollments, query
  end

  def down
    drop_view :report_enrollments
  end
end
