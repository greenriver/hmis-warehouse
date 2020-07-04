class CreateHudLookupTables < ActiveRecord::Migration[5.2]
  def change
    create_table :lookups_yes_no_etcs do |t|
      t.integer :value, null: false, index: true
      t.string :text, null: false
    end

    create_table :lookups_project_types do |t|
      t.integer :value, null: false, index: true
      t.string :text, null: false
    end

    create_table :lookups_living_situations do |t|
      t.integer :value, null: false, index: true
      t.string :text, null: false
    end

    create_table :lookups_funding_sources do |t|
      t.integer :value, null: false, index: true
      t.string :text, null: false
    end

    create_table :lookups_ethnicities do |t|
      t.integer :value, null: false, index: true
      t.string :text, null: false
    end

    create_table :lookups_genders do |t|
      t.integer :value, null: false, index: true
      t.string :text, null: false
    end

    create_table :lookups_relationships do |t|
      t.integer :value, null: false, index: true
      t.string :text, null: false
    end

    create_table :lookups_tracking_methods do |t|
      t.integer :value, index: true
      t.string :text, null: false
    end
  end
end
