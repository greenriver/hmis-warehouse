class CreateTeam < ActiveRecord::Migration[4.2]
  def change
    create_table :teams do |t|
      t.references :patient
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
