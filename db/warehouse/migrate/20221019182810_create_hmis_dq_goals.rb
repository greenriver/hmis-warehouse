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

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
