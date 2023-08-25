class MakeCareplansParanoid < ActiveRecord::Migration[6.1]
  def change
    add_column :pctp_careplans, :deleted_at, :timestamp
    add_column :pctp_care_goals, :deleted_at, :timestamp
    add_column :pctp_needs, :deleted_at, :timestamp
  end
end
