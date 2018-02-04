class CreateCohortClientChanges < ActiveRecord::Migration
  def change
    create_table :cohort_client_changes do |t|
      t.references :cohort_client, null: false
      t.references :cohort, null: false
      t.references :user, null: false
      t.string :change, index: true
      t.datetime :changed_at, null: false, index: true
      t.string :reason
    end
  end
end
