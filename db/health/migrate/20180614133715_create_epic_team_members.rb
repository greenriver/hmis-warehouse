class CreateEpicTeamMembers < ActiveRecord::Migration
  def change
    create_table :epic_team_members do |t|
      t.string :patient_id, null: false
      t.string :id_in_source
      t.string :name
      t.string :pcp_type
      t.string :relationship
      t.string :email
      t.string :phone
      t.datetime :processed
      t.integer :data_source_id, null: false
      t.timestamps
    end
  end
end
