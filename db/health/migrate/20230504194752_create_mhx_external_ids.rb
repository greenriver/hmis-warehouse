class CreateMhxExternalIds < ActiveRecord::Migration[6.1]
  def change
    create_table :mhx_external_ids do |t|
      t.references :client
      t.string :identifier
      t.boolean :valid_id
      t.timestamps
    end
  end
end
