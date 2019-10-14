class AddTraceIdToCps < ActiveRecord::Migration
  def change
    add_column :cps, :trace_id, :string, limit: 10
  end
end
