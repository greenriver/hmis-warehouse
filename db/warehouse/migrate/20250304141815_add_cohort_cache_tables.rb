# frozen_string_literal: true

class AddCohortCacheTables < ActiveRecord::Migration[7.0]
  def change
    create_table :cohort_client_data do |t|
      t.references :cohort, null: false # included to streamline maintenance
      t.references :cohort_client, null: false
      t.string :column_name, null: false

      t.integer :value_integer
      t.boolean :value_boolean
      t.string :value_string
      t.text :value_text
      t.date :value_date
      t.jsonb :value_json

      t.string :data_type, comment: 'Indicates which column is in-use for this row of data', null: false
    end

    create_table :cohort_column_metadata do |t|
      t.references :cohort, null: false
      t.string :name
      t.string :title
      t.string :description
      t.string :data_type
    end

    create_table :cohort_client_tabs do |t|
      t.references :cohort, null: false # included to streamline maintenance
      t.references :cohort_client, null: false
      t.string :tab_name
    end

    create_table :cohort_analytics_generations do |t|
      t.references :cohort
      t.string :process_name
      t.datetime :started_at
      t.datetime :completed_at
    end
  end
end
