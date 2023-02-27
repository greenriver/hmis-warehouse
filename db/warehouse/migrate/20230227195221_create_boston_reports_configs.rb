class CreateBostonReportsConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :boston_reports_configs do |t|
      t.string :total_color
      (0..9).each do |i|
        t.string "cohort_color_#{i}"
        t.string "stage_#{i}"
      end
      t.timestamps
    end
  end
end
