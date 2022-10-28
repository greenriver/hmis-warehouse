class AddProjectIdToCls < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_current_living_situations, :project_id, :integer
  end
end
