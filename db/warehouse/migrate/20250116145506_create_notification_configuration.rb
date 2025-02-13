class CreateNotificationConfiguration < ActiveRecord::Migration[7.0]
  def change
    create_table :notification_configurations do |t|
      t.references :user, null: false
      t.references :source, polymorphic: true, null: false
      t.string :notification_slug, null: false, description: 'Class name for notification logic'
      t.boolean :active, default: true
      t.timestamps
      t.timestamp :deleted_at
      t.index [:user_id, :source_id, :source_type, :notification_slug], unique: true, where: 'deleted_at is NULL', name: 'nc_user_source_slug_uniq_idx'
    end
    create_table :import_thresholds do |t|
      t.references :data_source, null: false
      t.integer :record_count_change_min_threshold
      t.integer :record_count_change_percent_threshold
      t.integer :error_count_min_threshold
      t.integer :error_percent_threshold
      t.boolean :pause_on_record_count_threshold
      t.boolean :pause_on_error_threshold
      t.timestamps
      t.timestamp :deleted_at
    end
  end
end
