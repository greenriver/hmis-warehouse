class AddUserDefinedCohortFields < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :user_string_1, :string
    add_column :cohort_clients, :user_string_2, :string
    add_column :cohort_clients, :user_string_3, :string
    add_column :cohort_clients, :user_string_4, :string

    add_column :cohort_clients, :user_boolean_1, :boolean
    add_column :cohort_clients, :user_boolean_2, :boolean
    add_column :cohort_clients, :user_boolean_3, :boolean
    add_column :cohort_clients, :user_boolean_4, :boolean

    add_column :cohort_clients, :user_select_1, :string
    add_column :cohort_clients, :user_select_2, :string
    add_column :cohort_clients, :user_select_3, :string
    add_column :cohort_clients, :user_select_4, :string

    add_column :cohort_clients, :user_date_1, :string
    add_column :cohort_clients, :user_date_2, :string
    add_column :cohort_clients, :user_date_3, :string
    add_column :cohort_clients, :user_date_4, :string
  end
end
