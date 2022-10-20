class CreateHmisDqGoals < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_dqt_goals do |t|
      t.string :coc_code
      (0..9).each do |num|
        t.string "segment_#{num}_name"
        t.string "segment_#{num}_color"
        t.integer "segment_#{num}_low"
        t.integer "segment_#{num}_high"
      end
      t.integer :es_stay_length
      t.integer :es_missed_exit_length
      t.integer :so_missed_exit_length
      t.integer :ph_missed_exit_length

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
