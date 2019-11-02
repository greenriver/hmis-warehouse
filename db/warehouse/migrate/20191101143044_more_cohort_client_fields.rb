class MoreCohortClientFields < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :user_numeric_5, :integer
    add_column :cohort_clients, :user_numeric_6, :integer
    add_column :cohort_clients, :user_numeric_7, :integer
    add_column :cohort_clients, :user_numeric_8, :integer
    add_column :cohort_clients, :user_numeric_9, :integer
    add_column :cohort_clients, :user_numeric_10, :integer

    add_column :cohort_clients, :user_select_5, :string
    add_column :cohort_clients, :user_select_6, :string
    add_column :cohort_clients, :user_select_7, :string
    add_column :cohort_clients, :user_select_8, :string
    add_column :cohort_clients, :user_select_9, :string
    add_column :cohort_clients, :user_select_10, :string

    add_column :cohort_clients, :user_date_5, :string
    add_column :cohort_clients, :user_date_6, :string
    add_column :cohort_clients, :user_date_7, :string
    add_column :cohort_clients, :user_date_8, :string
    add_column :cohort_clients, :user_date_9, :string
    add_column :cohort_clients, :user_date_10, :string
  end
end
