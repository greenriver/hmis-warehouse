class CreateAnsdEnrollments < ActiveRecord::Migration[6.1]
  def change
    create_table :ansd_enrollments do |t|
      t.references :report
      t.references :enrollment

      t.string :project_id
      t.string :project_name
      t.integer :project_type
      t.string :household_id
      t.string :household_type
      t.string :prior_living_situation_category
      t.date :entry_date
      t.date :move_in_date
      t.date :exit_date
      t.date :adjusted_exit_date
      t.string :exit_type
      t.integer :destination
      t.string :destination_text
      t.string :relationship
      t.string :client_id
      t.integer :age
      t.string :gender
      t.string :primary_race
      t.string :race_list
      t.string :ethnicity
      t.date :ce_entry_date
      t.date :ce_referral_date
      t.string :ce_referral_id
      t.date :return_date

      t.datetime :deleted_at
      t.timestamps
    end

    create_table :ansd_events do |t|
      t.references :enrollment

      t.string :event_id
      t.date :event_date
      t.integer :event
      t.integer :location
      t.string :project_name
      t.string :project_type
      t.integer :referral_result
      t.integer :result_date

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
