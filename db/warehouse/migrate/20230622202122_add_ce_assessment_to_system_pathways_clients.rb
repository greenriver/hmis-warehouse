class AddCeAssessmentToSystemPathwaysClients < ActiveRecord::Migration[6.1]
  def change
    add_column :system_pathways_clients, :ce_assessment, :boolean, default: false, null: false
  end
end
