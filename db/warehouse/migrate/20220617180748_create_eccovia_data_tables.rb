class CreateEccoviaDataTables < ActiveRecord::Migration[6.1]
  def change
    create_table :eccovia_fetches do |t|
      t.belongs_to :credentials
      t.belongs_to :data_source
      t.boolean :active, default: false, null: false
      t.datetime :last_fetched_at

      t.timestamps
      t.datetime :deleted_at
    end

    create_table :eccovia_assessments do |t|
      t.belongs_to :client
      t.belongs_to :data_source
      t.integer :score
      t.datetime :last_fetched_at

      t.timestamps
      t.datetime :deleted_at
    end

    create_table :eccovia_case_managers do |t|
      t.belongs_to :client
      t.belongs_to :data_source
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :cell
      t.datetime :last_fetched_at

      t.timestamps
      t.datetime :deleted_at
    end

    create_table :eccovia_client_contacts do |t|
      t.belongs_to :client
      t.belongs_to :data_source
      t.string :email
      t.string :phone
      t.string :cell
      t.string :street
      t.string :street2
      t.string :city
      t.string :state
      t.string :zip
      t.datetime :last_fetched_at

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
