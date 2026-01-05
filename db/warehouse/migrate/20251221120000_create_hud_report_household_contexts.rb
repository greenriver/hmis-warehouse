# frozen_string_literal: true

class CreateHudReportHouseholdContexts < ActiveRecord::Migration[7.1]
  def change
    create_table :hud_report_household_contexts do |t|
      t.references :report_instance, null: false, index: false
      t.references :service_history_enrollment, null: false
      t.references :source_enrollment
      t.references :destination_client
      t.references :source_client
      t.integer :age
      t.date :dob
      t.integer :veteran_status
      t.string :household_id
      t.references :hoh_destination_client
      t.string :hoh_personal_id
      t.references :hoh_service_history_enrollment
      t.date :hoh_entry_date
      t.date :hoh_exit_date
      t.integer :hoh_length_of_stay
      t.string :hoh_coc
      t.date :hoh_date_to_street
      t.date :hoh_move_in_date
      t.integer :hoh_age
      t.boolean :hoh_veteran
      t.boolean :is_hoh
      t.integer :relationship_to_hoh
      t.boolean :pit_chronic_status
      t.string :household_type
      t.boolean :is_parenting_youth
      t.boolean :has_other_clients_over_25
      t.boolean :inherited_chronic_status
      t.string :inherited_chronic_detail
      t.boolean :inherited_pit_chronic_status
      t.string :inherited_pit_chronic_detail
      t.date :inherited_move_in_date
      t.integer :member_count
      t.integer :hh_max_age
      t.boolean :hh_has_minor_children
      t.integer :hh_max_age_of_parents
      t.boolean :hh_any_veteran_chronic
      t.boolean :hh_any_veteran_non_chronic
      t.boolean :hh_all_adult_non_veteran
      t.boolean :hh_any_adult_refused_veteran
      t.boolean :hh_any_adult_missing_veteran

      t.timestamps
    end

    add_index :hud_report_household_contexts, [:report_instance_id, :service_history_enrollment_id],
              unique: true,
              name: 'index_hud_report_hh_contexts_on_report_and_she'

    add_column :hud_report_instances, :household_context_count, :integer
  end
end
