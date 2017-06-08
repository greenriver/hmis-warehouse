class CreateTeam < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.references :patient
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
