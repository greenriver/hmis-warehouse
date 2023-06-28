class CreateHapReportEraps < ActiveRecord::Migration[6.1]
  def change
    create_table :hap_report_eraps do |t|
      t.references :hap_report

      t.string :personal_id, null: false
      t.string :mci_id, null: false
      t.string :first_name
      t.string :last_name
      t.integer :age
      t.string :household_id
      t.boolean :head_of_household
      t.boolean :emancipated
      t.integer :project_type
      t.boolean :veteran
      t.boolean :mental_health_disorder
      t.boolean :substance_use_disorder
      t.boolean :survivor_of_domestic_violence
      t.integer :income_at_start
      t.integer :income_at_exit
      t.boolean :homeless
      t.integer :nights_in_shelter

      t.timestamps
    end
  end
end
