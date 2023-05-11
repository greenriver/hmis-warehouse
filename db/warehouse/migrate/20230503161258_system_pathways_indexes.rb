class SystemPathwaysIndexes < ActiveRecord::Migration[6.1]
  def change
    [:system_pathways_enrollments, :system_pathways_clients].each do |table|
      remove_index table, :report_id
      remove_index table, :client_id
      add_index table, [:client_id, :report_id], name: "c_r_#{table}_idx"
    end
  end
end
