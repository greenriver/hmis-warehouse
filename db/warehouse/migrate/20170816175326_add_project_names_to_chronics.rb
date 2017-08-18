class AddProjectNamesToChronics < ActiveRecord::Migration
  def change
    add_column :chronics, :project_names, :string
  end
end
