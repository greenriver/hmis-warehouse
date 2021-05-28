class StoreCensusData < ActiveRecord::Migration[5.2]
  def change
    reversible do |r|
      r.up do
        execute <<-SQL
          CREATE TYPE public.census_levels AS ENUM (
              'STATE',
              'COUNTY',
              'PLACE',
              'SLDU',
              'SLDL',
              'ZCTA5',
              'TRACT',
              'BG',
              'TABBLOCK',
              'CUSTOM'
          );
        SQL
      end

      r.down do
        execute("DROP TYPE census_levels")
      end
    end

    create_table "census_groups", force: :cascade do |t|
      t.integer "year", null: false
      t.string "dataset", null: false
      t.string "name", null: false
      t.text "description", null: false
      t.date "created_on"
      t.index ["year", "dataset", "name"], name: "index_census_groups_on_year_and_dataset_and_name", unique: true
    end

    create_table "census_variables", force: :cascade do |t|
      t.integer "year", null: false
      t.boolean "downloaded", default: false, null: false
      t.string "dataset", null: false
      t.string "name", null: false
      t.text "label", null: false
      t.text "concept", null: false
      t.string "census_group", null: false
      t.string "census_attributes", null: false
      t.string "internal_name"
      t.date "created_on", null: false
      t.index ["dataset"], name: "index_census_variables_on_dataset"
      t.index ["internal_name", "year", "dataset"], name: "index_census_variables_on_internal_name_and_year_and_dataset", where: "(internal_name IS NOT NULL)"
      t.index ["year", "dataset", "name"], name: "index_census_variables_on_year_and_dataset_and_name", unique: true
    end

    create_table "census_values", force: :cascade do |t|
      t.references :census_variable, null: false
      t.numeric :value, null: false
      t.string :full_geoid, null: false
      t.date :created_on, null: false
    end

    reversible do |r|
      r.up do
        execute <<-SQL
          ALTER TABLE census_values
          ADD COLUMN census_level census_levels not null;

          CREATE INDEX index_census_values_on_full_geoid ON public.census_values USING btree (full_geoid);

          CREATE UNIQUE INDEX index_census_values_on_full_geoid_and_census_variable_id ON public.census_values USING btree (full_geoid, census_variable_id);

          CREATE INDEX index_census_values_on_census_level ON public.census_values USING btree (census_level);
        SQL
      end
    end
  end
end
