class CreateServiceHistoryView < ActiveRecord::Migration
  def up
    # execute <<-SQL
    #   CREATE MATERIALIZED VIEW recent_service_history
    #   as (
    #     SELECT * from warehouse_client_service_history
    #     WHERE date > '#{1.years.ago.to_date}'
    #   );
    # SQL

    # add_index :recent_service_history, :id, unique: true
    # add_index :recent_service_history, :date
    # add_index :recent_service_history, :client_id
    # add_index :recent_service_history, :household_id
    # add_index :recent_service_history, :project_type
    # add_index :recent_service_history, :record_type
    # add_index :recent_service_history, :project_tracking_method
    # add_index :recent_service_history, :computed_project_type
  end

  def down
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS recent_service_history;
    SQL
  end
end
