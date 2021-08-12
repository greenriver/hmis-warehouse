class CreateHomelessSummaryReportClients < ActiveRecord::Migration[5.2]
  def change
    create_table :homeless_summary_report_clients do |t|
      t.references :client
      t.references :report

      t.string :first_name
      t.string :last_name

      t.integer :spm_m1a_es_sh_days
      t.integer :spm_m1a_es_sh_th_days
      t.integer :spm_m1b_es_sh_ph_days
      t.integer :spm_m1b_es_sh_th_ph_days

      t.integer :spm_m2_reentry_days

      t.integer :spm_m7a1_destination
      t.integer :spm_m7b1_destination
      t.integer :spm_m7b2_destination
      t.boolean :spm_m7a1_c2
      t.boolean :spm_m7a1_c3
      t.boolean :spm_m7a1_c4
      t.boolean :spm_m7b1_c2
      t.boolean :spm_m7b1_c3
      t.boolean :spm_m7b2_c2
      t.boolean :spm_m7b2_c3

      t.integer :spm_all_persons
      t.integer :spm_without_children
      t.integer :spm_with_children
      t.integer :spm_only_children
      t.integer :spm_without_children_and_fifty_five_plus
      t.integer :spm_adults_with_children_where_parenting_adult_18_to_24
      t.integer :spm_white_non_hispanic_latino
      t.integer :spm_hispanic_latino
      t.integer :spm_black_african_american
      t.integer :spm_asian
      t.integer :spm_american_indian_alaskan_native
      t.integer :spm_native_hawaiian_other_pacific_islander
      t.integer :spm_multi_racial
      t.integer :spm_fleeing_dv
      t.integer :spm_veteran
      t.integer :spm_has_disability
      t.integer :spm_has_rrh_move_in_date
      t.integer :spm_has_psh_move_in_date
      t.integer :spm_first_time_homeless
      t.integer :spm_returned_to_homelessness_from_permanent_destination

      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end
  end
end
