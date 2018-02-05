class AlterIndexesOnServiceHistoryServices < ActiveRecord::Migration
  def up
    GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, name|
      remove_index name, name: "index_shs_#{year}_date_en_id"
      remove_index name, name: "index_shs_#{year}_date_client_id"
      remove_index name, name: "index_shs_#{year}_date_project_type"

      add_index name, [:service_history_enrollment_id, :date, :record_type], name: "index_shs_#{year}_date_en_id" 
      add_index name, [:client_id, :date, :record_type], name: "index_shs_#{year}_date_client_id"
      add_index name, [:project_type, :date, :record_type], name: "index_shs_#{year}_date_project_type"

    end
  end

  def down
    GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, name|
      remove_index name, name: "index_shs_#{year}_date_en_id"
      remove_index name, name: "index_shs_#{year}_date_client_id"
      remove_index name, name: "index_shs_#{year}_date_project_type"

      add_index name, [:date, :service_history_enrollment_id], name: "index_shs_#{year}_date_en_id" 
      add_index name, [:date, :client_id], name: "index_shs_#{year}_date_client_id"
      add_index name, [:date, :project_type], name: "index_shs_#{year}_date_project_type"

    end
  end
end
