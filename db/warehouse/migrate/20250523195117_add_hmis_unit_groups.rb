###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddHmisUnitGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :hmis_unit_groups do |t|
      t.string :name, null: false
      t.references :project, null: false, foreign_key: { to_table: :Project }
      t.string :workflow_template_identifier, null: true # which workflow template to use to fill units in this group. use identifier instead of db id to avoid tying to a particular version of the template. nullable for non-CE usage
      t.timestamps
      t.timestamp :deleted_at
    end

    add_column :hmis_units, :hmis_unit_group_id, :integer, null: true
  end
end

# rails db:migrate:up:warehouse VERSION=20250523195117 RAILS_ENV=development
# rails db:migrate:down:warehouse VERSION=20250523195117 RAILS_ENV=development
