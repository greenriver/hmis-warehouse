class AddEventTypeToResults < ActiveRecord::Migration[6.1]
  def change
    add_column :ce_performance_results, :event_type, :integer
    add_column :ce_performance_clients, :assessment_type, :string
  end
end
