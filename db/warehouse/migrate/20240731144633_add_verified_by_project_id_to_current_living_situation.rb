class AddVerifiedByProjectIdToCurrentLivingSituation < ActiveRecord::Migration[7.0]
  def change
    add_column :CurrentLivingSituation, :verified_by_project_id, :integer
    add_foreign_key :CurrentLivingSituation, :Project, column: :verified_by_project_id, validate: false
  end
end
