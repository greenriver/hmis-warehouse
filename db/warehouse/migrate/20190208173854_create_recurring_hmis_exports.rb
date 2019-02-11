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
# attribute :start_date, Date, default: 1.years.ago.to_date
# attribute :end_date, Date, default: Date.today
# attribute :hash_status, Integer, default: 1
# attribute :period_type, Integer, default: 3
# attribute :directive, Integer, default: 2
# attribute :include_deleted,  Boolean, default: false
# attribute :project_ids, Array, default: []
# attribute :project_group_ids, Array, default: []
# attribute :organization_ids, Array, default: []
# attribute :data_source_ids, Array, default: []
# attribute :user_id, Integer, default: nil
# attribute :faked_pii, Boolean, default: false
#
# attribute :every_n_days, Integer, default: 0
# attribute :reporting_range, Integer, default: 0
# attribute :reporting_range_days, Integer, default: 0
