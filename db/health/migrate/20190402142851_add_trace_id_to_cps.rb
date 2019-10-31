class AddTraceIdToCps < ActiveRecord::Migration[4.2]
  def change
    add_column :cps, :trace_id, :string, limit: 10
  end
end
