class AddReportServiceView < ActiveRecord::Migration
  def up
    model = GrdaWarehouse::Hud::Service
    report_demographic_table = Arel::Table.new :report_demographics
    gh_service_table         = model.arel_table
    query = gh_service_table.project(
      *gh_service_table.engine.column_names.map(&:to_sym).map{ |c| gh_service_table[c] },
      report_demographic_table[:id].as('demographic_id'),
      report_demographic_table[:client_id]
    ).
      join(report_demographic_table).on(
        report_demographic_table[:data_source_id].eq(gh_service_table[:data_source_id]).and( report_demographic_table[:PersonalID].eq gh_service_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_services, query
  end

  def down
    drop_view :report_services
  end
end
