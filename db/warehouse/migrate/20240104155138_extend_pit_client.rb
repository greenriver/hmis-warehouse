class ExtendPitClient < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      change_table :hud_report_pit_clients do |t|
        # 2024 Gender fields
        t.integer :culturally_specific
        t.integer :different_identity
        t.integer :non_binary
        t.boolean :more_than_one_gender

        # 2024 Race fields
        t.integer :mid_east_n_african
      end
    }
  end
end
