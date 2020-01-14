class AddProjectNamesToChronics < ActiveRecord::Migration[4.2]
  def change
    add_column :chronics, :project_names, :string
  end
end
