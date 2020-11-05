class AddDeletedAtToCha < ActiveRecord::Migration[5.2]
  def change
    add_column :comprehensive_health_assessments, :deleted_at, :datetime
  end
end
