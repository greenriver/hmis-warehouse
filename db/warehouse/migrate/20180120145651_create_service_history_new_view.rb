class CreateServiceHistoryNewView < ActiveRecord::Migration
  include ArelHelper
  def up

    def shs_columns
      cols = she_columns.dup
      GrdaWarehouse::ServiceHistoryService.column_names.map do |col|
        cols[col] = shs_t[col.to_sym].as(col).to_sql
      end
      cols.except('service_history_enrollment_id')
    end

    def she_columns
      GrdaWarehouse::ServiceHistoryEnrollment.column_names.map do |col|
        [col, she_t[col.to_sym].as(col).to_sql]
      end.to_h
    end

    services = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).
      select(shs_columns)

    enrollments = GrdaWarehouse::ServiceHistoryEnrollment.select(she_columns)

    service_history_table = Arel::Table.new('service_history')
    view_sql = Arel.sql(shs_t.join(she_t).on(shs_t[:service_history_enrollment_id].eq(she_t[:id])).project(*shs_columns.values).
      union(
        she_t.project(*she_columns.values)
        ).to_sql
      )
    

    create_view :service_history, view_sql
  end
  def down
    drop_view :service_history
  end
end
