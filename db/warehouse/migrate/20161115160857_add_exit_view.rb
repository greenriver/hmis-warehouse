class AddExitView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Exit
    report_enrollment_table = Arel::Table.new :report_enrollments
    gh_exit_table = model.arel_table
    query = gh_exit_table.project(
      *gh_exit_table.engine.column_names.map(&:to_sym).map{ |c| gh_exit_table[c] },  # all the exit columns
      report_enrollment_table[:id].as('enrollment_id'),                              # a fake enrollment foreign key
      report_enrollment_table[:client_id]                                            # a fake destination client foreign key
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_exit_table[:data_source_id]).
        and( report_enrollment_table[:ProjectEntryID].eq gh_exit_table[:ProjectEntryID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_exits, query
  end

  def down
    drop_view :report_exits
  end
end
