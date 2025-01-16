class CreateNotificationConfiguration < ActiveRecord::Migration[7.0]
  def change
    create_table :notification_configurations do |t|
      t.references :user, null: false
      t.references :source, polymorphic: true, null: false
      t.references :notification_type, polymorphic: true, null: false
      t.boolean :active, default: :true
      t.timestamps
      t.timestamp :deleted_at
    end
    create_table :notification_types do |t|
      t.string :type, null: false
      t.boolean :active, default: false
      t.timestamps
      t.timestamp :deleted_at
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
