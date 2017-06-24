class RecreateClientMatches < ActiveRecord::Migration
  def change
    drop_table :client_matches if table_exists? :client_matches
    create_table :client_matches do |t|
      t.references :source_client, index: true, foreign_key: false,  null: false
      t.references :destination_client, index: true, foreign_key: false,  null: false
      t.references :updated_by, index: true
      t.integer :lock_version
      t.integer :defer_count
      t.string :status,  null: false
      t.float :score,  null: true
      t.text :score_details
      t.timestamps null: false
    end
  end
end
