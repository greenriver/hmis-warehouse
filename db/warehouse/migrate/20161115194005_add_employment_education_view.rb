class AddEmploymentEducationView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::EmploymentEducation
    report_enrollment_table  = Arel::Table.new :report_enrollments
    report_demographic_table = Arel::Table.new :report_demographics
    gh_em_ed_table           = model.arel_table 
    query = gh_em_ed_table.project(
      *gh_em_ed_table.engine.column_names.map(&:to_sym).map{ |c| gh_em_ed_table[c] },  # all employment education columns
      report_enrollment_table[:id].as('enrollment_id'),                                # a fake enrollment foreign key
      report_demographic_table[:id].as('demographic_id'),                              # a fake source client foreign key
      report_demographic_table[:client_id]                                             # a fake destination client foreign key
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_em_ed_table[:data_source_id]).
        and( report_enrollment_table[:ProjectEntryID].eq gh_em_ed_table[:ProjectEntryID] )
      ).
      join(report_demographic_table).on(
        report_demographic_table[:data_source_id].eq(gh_em_ed_table[:data_source_id]).
        and( report_demographic_table[:PersonalID].eq gh_em_ed_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_employment_educations, query
  end

  def down
    drop_view :report_employment_educations
  end
end
