# frozen_string_literal: true

class CreateHudReportHouseholdContexts < ActiveRecord::Migration[7.1]
  def change
    create_table :hud_report_household_contexts do |t|
      t.references :report_instance, null: false, index: false
      t.references :service_history_enrollment, null: false
      t.references :source_enrollment
      t.references :source_client
      t.integer :age
      t.string :household_id
      t.integer :hoh_id
      t.references :hoh_service_history_enrollment
      t.date :hoh_entry_date
      t.string :hoh_coc
      t.date :hoh_date_to_street
      t.date :hoh_move_in_date
      t.integer :hoh_age
      t.boolean :hoh_veteran
      t.boolean :is_hoh
      t.string :household_type
      t.boolean :is_parenting_youth
      t.boolean :has_other_clients_over_25
      t.boolean :inherited_chronic_status
      t.string :inherited_chronic_detail
      t.date :inherited_move_in_date
      t.integer :member_count
      t.integer :hh_max_age
      t.boolean :hh_has_minor_children
      t.integer :hh_max_age_of_parents

      t.timestamps
    end

    add_index :hud_report_household_contexts, [:report_instance_id, :service_history_enrollment_id],
              unique: true,
              name: 'index_hud_report_hh_contexts_on_report_and_she'

    add_column :hud_report_instances, :household_context_count, :integer
  end
end
