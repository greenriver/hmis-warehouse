class CreateHudSpmEnrollments < ActiveRecord::Migration[6.1]
  def change
    # Collects the universe of potentially contributing HMIS enrollments
    create_table :hud_report_spm_enrollments do |t|
      t.string :first_name
      t.string :last_name
      t.string :personal_id
      t.integer :data_source_id
      t.date :start_of_homelessness
      t.date :entry_date
      t.date :exit_date # coalesce with report_end_date when finding episodes
      t.date :move_in_date
      t.integer :project_type
      t.boolean :eligible_funding
      t.integer :prior_living_situation
      t.integer :length_of_stay
      t.boolean :los_under_threshold
      t.boolean :previous_street_essh
      t.integer :destination
      t.integer :age # age at later of entry_date and report_start_date
      t.integer :previous_earned_income
      t.integer :previous_non_employment_income
      t.integer :previous_total_income
      t.integer :current_earned_income
      t.integer :current_non_employment_income
      t.integer :current_total_income

      t.references :report_instance, index: true
      t.references :client, index: true # warehouse destination client, for de-duplication
      t.references :previous_income_benefits # annual or initial as appropriate
      t.references :current_income_benefits # at annual or, exit as appropriate
      t.references :enrollment

      t.index [:personal_id, :data_source_id], unique: false, name: :spm_p_id_ds_id
    end

    # Summarizes the enrollment episode for measure 1
    create_table :hud_report_spm_episodes do |t|
      t.date :first_date
      t.date :last_date
      t.integer :days_homeless
      t.boolean :literally_homeless_at_entry
      t.references :client, index: true # warehouse destination client, for de-duplication
    end

    # Join table
    create_table :hud_report_spm_enrollment_links do |t|
      t.references :enrollment
      t.references :episode
    end

    # contributing bed nights for night by night enrollments
    create_table :hud_report_spm_bed_nights do |t|
      t.date :date
      t.references :episode
      t.references :service
      t.references :enrollment
      t.references :client, index: true # warehouse destination client, for de-duplication
    end

    # measure 2
    create_table :hud_report_spm_returns do |t|
      t.date :exit_date
      t.date :return_date
      t.integer :exit_destination
      t.references :exit_enrollment
      t.references :return_enrollment
      t.references :client, index: true # warehouse destination client, for de-duplication
    end
  end
end
