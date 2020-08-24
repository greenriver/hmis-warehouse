class AddDqToAprClients < ActiveRecord::Migration[5.2]
  def change
    change_table :hud_report_apr_clients do |t|
      t.string :first_name
      t.string :last_name
      t.integer :name_quality
      t.string :ssn
      t.integer :ssn_quality
      t.date :dob
      t.integer :dob_quality
      t.date :enrollment_created
      t.jsonb :race
      t.integer :ethnicity
      t.integer :gender
    end
  end
end
