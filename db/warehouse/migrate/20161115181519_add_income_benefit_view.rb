class AddIncomeBenefitView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::IncomeBenefit
    report_enrollment_table  = Arel::Table.new :report_enrollments
    report_demographic_table = Arel::Table.new :report_demographics
    gh_income_benefit_table  = model.arel_table 
    query = gh_income_benefit_table.project(
      *gh_income_benefit_table.engine.column_names.map(&:to_sym).map{ |c| gh_income_benefit_table[c] },
      report_enrollment_table[:id].as('enrollment_id'),
      report_demographic_table[:id].as('demographic_id'),
      report_demographic_table[:client_id]
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_income_benefit_table[:data_source_id]).
        and( report_enrollment_table[:ProjectEntryID].eq gh_income_benefit_table[:ProjectEntryID] )
      ).
      join(report_demographic_table).on(
        report_demographic_table[:data_source_id].eq(gh_income_benefit_table[:data_source_id]).
        and( report_demographic_table[:PersonalID].eq gh_income_benefit_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( gh_income_benefit_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_income_benefits, query
  end

  def down
    drop_view :report_income_benefits
  end
end
