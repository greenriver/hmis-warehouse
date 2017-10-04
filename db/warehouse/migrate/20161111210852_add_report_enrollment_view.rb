class AddReportEnrollmentView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Enrollment
    report_demographic_table = Arel::Table.new :report_demographics
    gh_enrollment_table      = model.arel_table
    query = gh_enrollment_table.
      project(
        *gh_enrollment_table.engine.column_names.map(&:to_sym).map{ |c| gh_enrollment_table[c] },  # all the enrollment columns
        report_demographic_table[:id].as('demographic_id'),                                        # the source client id
        report_demographic_table[:client_id]                                                       # the destination client id
      ).
      outer_join(report_demographic_table).on(
        report_demographic_table[:data_source_id].eq( gh_enrollment_table[:data_source_id]).
        and( report_demographic_table[:PersonalID].eq gh_enrollment_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_enrollments, query
  end

  def down
    drop_view :report_enrollments
  end
end
