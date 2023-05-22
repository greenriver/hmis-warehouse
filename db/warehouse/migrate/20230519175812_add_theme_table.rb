class AddThemeTable < ActiveRecord::Migration[6.1]
  def change
    create_table :themes do |t|
      t.string :client, null: false
      t.string :hmis_origin
      t.jsonb :hmis_value

      t.timestamps
    end
  end
end
