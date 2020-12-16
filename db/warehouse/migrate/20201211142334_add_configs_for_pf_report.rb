class AddConfigsForPfReport < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :pf_universal_data_element_threshold, :integer, default: 2, null: false
    add_column :configs, :pf_utilization_min, :integer, default: 66, null: false
    add_column :configs, :pf_utilization_max, :integer, default: 104, null: false
    add_column :configs, :pf_timeliness_threshold, :integer, default: 3, null: false
    add_column :configs, :pf_show_income, :boolean, default: false, null: false
    add_column :configs, :pf_show_additional_timeliness, :boolean, default: false, null: false
  end
end
