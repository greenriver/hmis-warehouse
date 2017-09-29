class AddHealthAndDvView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::HealthAndDv
    report_enrollment_table  = Arel::Table.new :report_enrollments
    report_demographic_table = Arel::Table.new :report_demographics
    gh_health_and_dv_table   = model.arel_table 
    query = gh_health_and_dv_table.project(
      *gh_health_and_dv_table.engine.column_names.map(&:to_sym).map{ |c| gh_health_and_dv_table[c] },
      report_enrollment_table[:id].as('enrollment_id'),
      report_demographic_table[:id].as('demographic_id'),
      report_demographic_table[:client_id]
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_health_and_dv_table[:data_source_id]).
        and( report_enrollment_table[:ProjectEntryID].eq gh_health_and_dv_table[:ProjectEntryID] )
      ).
      join(report_demographic_table).on(
        report_demographic_table[:data_source_id].eq(gh_health_and_dv_table[:data_source_id]).
        and( report_demographic_table[:PersonalID].eq gh_health_and_dv_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_health_and_dvs, query
  end

  def down
    drop_view :report_health_and_dvs
  end
end
