class RenameCurrentLivingSituation < ActiveRecord::Migration[6.1]
  def change
    rename_column :hmis_dqt_current_living_situations, :current_living_situation, :situation

    drop_table :hmis_dqt_services
    drop_table :hmis_dqt_projects
  end
end
