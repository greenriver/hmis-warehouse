class AddAgenciesTable < ActiveRecord::Migration
  def change
    create_table :agencies do |t|
      t.string :name
      t.timestamps null: false
    end

    add_reference :users, :agency
  end
end
