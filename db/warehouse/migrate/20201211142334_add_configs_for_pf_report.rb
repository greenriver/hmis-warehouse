class AddConfigsForPfReport < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :pf_universal_data_element_threshold, :integer, default: 2
    add_column :configs, :pf_utilization_min, :integer, default: 66
    add_column :configs, :pf_utilization_max, :integer, default: 104
    add_column :configs, :pf_timeliness_threshold, :integer, default: 3
    add_column :configs, :pf_show_income, :boolean, default: false
    add_column :configs, :pf_show_additional_timeliness, :boolean, default: false
  end
end
