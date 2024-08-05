class AddVerifiedByProjectIdToCurrentLivingSituation < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :CurrentLivingSituation, :verified_by_project, index: { algorithm: :concurrently }, null: true
    add_foreign_key :CurrentLivingSituation, :Project, column: :verified_by_project_id, validate: false
  end
end
