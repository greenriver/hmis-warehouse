class CreateLongitudinalSpm < ActiveRecord::Migration[6.1]
  def change
    create_table :longitudinal_spms do |t|
      t.belongs_to :user
      t.jsonb :options
      t.string :processing_errors
      t.timestamp :started_at
      t.timestamp :completed_at
      t.timestamp :failed_at

      t.timestamps
      t.datetime :deleted_at
    end
    create_table :longitudinal_spm_spms do |t|
      t.belongs_to :report, null: false
      t.belongs_to :spm, null: false
      t.date :start_date
      t.date :end_date
      t.timestamps
      t.datetime :deleted_at
    end
    create_table :longitudinal_spm_results do |t|
      t.belongs_to :report, null: false
      t.belongs_to :spm, null: false
      t.date :start_date
      t.date :end_date
      t.string :measure
      t.string :table
      t.string :cell
      t.float :value

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
