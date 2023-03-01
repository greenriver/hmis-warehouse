class CreateBostonReportsConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :boston_report_configs do |t|
      t.string :total_color
      (0..9).each do |i|
        t.string "breakdown_1_color_#{i}"
        t.string "breakdown_2_color_#{i}"
        t.string "breakdown_3_color_#{i}"
        t.string "breakdown_4_color_#{i}"
      end
      t.timestamps
    end
  end
end
