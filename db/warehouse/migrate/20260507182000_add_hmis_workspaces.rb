# frozen_string_literal: true

class AddHmisWorkspaces < ActiveRecord::Migration[7.1]
  def change
    create_table :hmis_workspaces do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :applies_to, null: false
      t.references :data_source, null: false
      t.references :hmis_project_group, null: false, foreign_key: { to_table: :hmis_project_groups }
      t.integer :sort_order, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # slug is unique per data source for the specified usage (applies_to)
    add_index :hmis_workspaces, [:applies_to, :slug, :data_source_id], unique: true
  end
end

# rails db:migrate:up:warehouse VERSION=20260507182000
# rails db:migrate:down:warehouse VERSION=20260507182000
