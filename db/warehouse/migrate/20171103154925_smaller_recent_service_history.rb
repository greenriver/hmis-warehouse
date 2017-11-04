class SmallerRecentServiceHistory < ActiveRecord::Migration
  include ArelHelper
  def up
    sql = GrdaWarehouse::ServiceHistory.service.joins(project: :organization).
      where(date: [2.months.ago.to_date..1.months.ago.to_date]).
      select(*columns).to_sql
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS recent_service_history;
    SQL
    execute <<-SQL
      CREATE MATERIALIZED VIEW recent_service_history AS (#{sql});
    SQL

    add_index :recent_service_history, :id, unique: true
    add_index :recent_service_history, :date
    add_index :recent_service_history, :client_id
    add_index :recent_service_history, :household_id
    add_index :recent_service_history, :project_type
    add_index :recent_service_history, :project_tracking_method
    add_index :recent_service_history, :computed_project_type
  end

  def down
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS recent_service_history;
    SQL
  end

  def columns
    [
      :id,
      :client_id,
      :data_source_id,
      :date,
      :first_date_in_program,
      :last_date_in_program,
      :enrollment_group_id,
      :age,
      :destination,
      :head_of_household_id,
      :household_id,
      p_t[:id].as('project_id').to_sql,
      :project_type,
      :project_tracking_method,
      o_t[:id].as('organization_id').to_sql,
      :housing_status_at_entry,
      :housing_status_at_exit,
      :service_type,
      :computed_project_type,
      :presented_as_individual,
    ]
  end
end
