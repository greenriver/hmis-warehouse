class CreateRecurringHmisExports < ActiveRecord::Migration
  def change
    create_table :recurring_hmis_exports do |t|
      t.integer :every_n_days
      t.integer :reporting_range
      t.integer :reporting_range_days
      t.references :hmis_export

      # HmisExport fields
      t.date :start_date
      t.date :end_date
      t.integer :hash_status
      t.integer :period_type
      t.integer :directive
      t.boolean :include_deleted
      t.integer :user_id
      t.boolean :faked_pii
      # serialized
      t.string :project_ids
      t.string :project_group_ids
      t.string :organization_ids
      t.string :data_source_ids

      t.timestamps
    end
  end
end
