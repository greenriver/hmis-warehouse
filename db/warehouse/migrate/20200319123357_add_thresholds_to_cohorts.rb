class AddThresholdsToCohorts < ActiveRecord::Migration[5.2]
  def change
    (1..5).each do |i|
      add_column :cohorts, "threshold_row_#{i}", :integer
      add_column :cohorts, "threshold_color_#{i}", :string
      add_column :cohorts, "threshold_label_#{i}", :string
    end
  end
end
