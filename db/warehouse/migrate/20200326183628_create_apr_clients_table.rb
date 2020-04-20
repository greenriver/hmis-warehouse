class CreateAprClientsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_apr_clients do |t|
      t.integer :age
      t.boolean :head_of_household
      t.boolean :parenting_youth
      t.date :first_date_in_program
      t.date :last_date_in_program
      t.boolean :veteran
      t.integer :longest_stay
      t.boolean :chronically_homeless

      t.timestamps
    end
  end
end
