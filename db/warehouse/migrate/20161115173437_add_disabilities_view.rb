class AddDisabilitiesView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Disability
    report_enrollment_table  = Arel::Table.new :report_enrollments
    report_demographic_table = Arel::Table.new :report_demographics
    gh_disability_table      = model.arel_table 
    query = gh_disability_table.project(
      *gh_disability_table.engine.column_names.map(&:to_sym).map{ |c| gh_disability_table[c] },  # all disability columns
      report_enrollment_table[:id].as('enrollment_id'),                                          # a fake foreign key to the enrollments table
      report_demographic_table[:id].as('demographic_id'),                                        # a fake foreign key to the source client
      report_demographic_table[:client_id]                                                       # a fake fore
    ).
      outer_join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_disability_table[:data_source_id]).
        and( report_enrollment_table[:ProjectEntryID].eq gh_disability_table[:ProjectEntryID] )
      ).
      outer_join(report_demographic_table).on(
        report_demographic_table[:data_source_id].eq(gh_disability_table[:data_source_id]).
        and( report_demographic_table[:PersonalID].eq gh_disability_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( gh_disability_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_disabilities, query
  end

  def down
    drop_view :report_disabilities
  end
end
