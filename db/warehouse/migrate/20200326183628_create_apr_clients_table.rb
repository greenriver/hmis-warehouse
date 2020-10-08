class CreateAprClientsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_apr_clients do |t|
      t.integer :age
      t.boolean :head_of_household
      t.string :head_of_household_id
      t.boolean :parenting_youth
      t.date :first_date_in_program
      t.date :last_date_in_program
      t.integer :veteran_status
      t.integer :length_of_stay
      t.boolean :chronically_homeless

      t.timestamps
    end
  end
end
