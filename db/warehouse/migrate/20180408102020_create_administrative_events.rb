class CreateAdministrativeEvents < ActiveRecord::Migration
  def change
    create_table :administrative_events do |t|
      t.string :user_id
      t.date :date
      t.string :title
      t.string :description

      t.timestamps null: false
    end
  end
end
