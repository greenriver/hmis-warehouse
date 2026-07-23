###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHmisRestrictedRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :hmis_restricted_records do |t|
      t.references :restrictable, polymorphic: true, null: false, index: false
      t.references :data_source, null: false, index: true
      t.references :created_by, null: false, index: false

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    add_index(
      :hmis_restricted_records,
      [:restrictable_type, :restrictable_id],
      unique: true,
      where: 'deleted_at IS NULL',
      name: 'index_hmis_restricted_records_on_restrictable',
    )
    add_index :hmis_restricted_records, [:data_source_id, :restrictable_type]
  end
end
# rails db:migrate:up:warehouse VERSION=20260624120000
# rails db:migrate:down:warehouse VERSION=20260624120000
