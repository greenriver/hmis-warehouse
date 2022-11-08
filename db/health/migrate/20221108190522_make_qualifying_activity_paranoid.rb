class MakeQualifyingActivityParanoid < ActiveRecord::Migration[6.1]
  def change
    add_column :qualifying_activities, :deleted_at, :date
  end
end
