class IndexesForHoused < ActiveRecord::Migration[4.2]
  def change
    add_index :warehouse_houseds, [:project_type, :search_start, :search_end, :service_project, :housed_date, :housing_exit, :project_id], name: :housed_p_type_s_dates_h_dates_p_id
    add_index :warehouse_houseds, [:project_type, :search_start, :search_end, :service_project, :project_id], name: :housed_p_type_s_dates_p_id
    add_index :warehouse_houseds, [:project_type, :housed_date, :housing_exit, :project_id], name: :housed_p_type_h_dates_p_id
  end
end
