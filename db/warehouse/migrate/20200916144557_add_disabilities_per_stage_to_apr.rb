class AddDisabilitiesPerStageToApr < ActiveRecord::Migration[5.2]
  def change

    change_table :hud_report_apr_clients do |t|
      t.integer :developmental_disability_entry
      t.integer :hiv_aids_entry
      t.integer :physical_disability_entry
      t.integer :chronic_disability_entry
      t.integer :mental_health_problem_entry
      t.integer :substance_abuse_entry
      t.boolean :alcohol_abuse_entry
      t.boolean :drug_abuse_entry
      t.integer :developmental_disability_exit
      t.integer :hiv_aids_exit
      t.integer :physical_disability_exit
      t.integer :chronic_disability_exit
      t.integer :mental_health_problem_exit
      t.integer :substance_abuse_exit
      t.boolean :alcohol_abuse_exit
      t.boolean :drug_abuse_exit
      t.integer :developmental_disability_latest
      t.integer :hiv_aids_latest
      t.integer :physical_disability_latest
      t.integer :chronic_disability_latest
      t.integer :mental_health_problem_latest
      t.integer :substance_abuse_latest
      t.boolean :alcohol_abuse_latest
      t.boolean :drug_abuse_latest
    end
  end
end
