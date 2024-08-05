class AddVerifiedByProjectIdToCurrentLivingSituation < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # Ignore StrongMigrations for this one. It complains that validating foreign key locks up both tables, but
      # in this case it's validating a column that'll be all nulls, so it should still be fast enough.
      add_reference :CurrentLivingSituation, :verified_by_project, foreign_key: { to_table: :Project }, index: true, null: true
    end
  end
end
