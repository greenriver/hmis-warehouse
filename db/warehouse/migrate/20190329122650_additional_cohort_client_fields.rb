class AdditionalCohortClientFields < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :vispdat_score_manual, :integer
    add_column :cohort_clients, :user_numeric_1, :integer
    add_column :cohort_clients, :user_numeric_2, :integer
    add_column :cohort_clients, :user_numeric_3, :integer
    add_column :cohort_clients, :user_numeric_4, :integer
    add_column :cohort_clients, :user_string_5, :string
    add_column :cohort_clients, :user_string_6, :string
    add_column :cohort_clients, :user_string_7, :string
    add_column :cohort_clients, :user_string_8, :string
  end
end
