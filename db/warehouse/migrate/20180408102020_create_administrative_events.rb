class CreateAdministrativeEvents < ActiveRecord::Migration
  def change
    create_table :administrative_events do |t|
      t.references :user, null: false
      t.date :date, null: false
      t.string :title, null: false
      t.string :description

      t.timestamps null: false
    end
  end
end
