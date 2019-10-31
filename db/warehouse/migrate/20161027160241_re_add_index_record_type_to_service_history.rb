class ReAddIndexRecordTypeToServiceHistory < ActiveRecord::Migration[4.2]
  def up
    unless index_exists?(:warehouse_client_service_history, :record_type)
      add_index :warehouse_client_service_history, :record_type
    end
  end
end
