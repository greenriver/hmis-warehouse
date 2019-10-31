class AddAgenciesTable < ActiveRecord::Migration[4.2]
  def change
    create_table :agencies do |t|
      t.string :name
      t.timestamps null: false
    end

    add_reference :users, :agency
  end
end
