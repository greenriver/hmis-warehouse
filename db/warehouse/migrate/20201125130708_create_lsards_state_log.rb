class CreateLsardsStateLog < ActiveRecord::Migration[5.2]
  def change
    create_table :lsa_rds_state_logs do |t|
      t.string :state
      t.timestamps null: false
    end
  end
end
