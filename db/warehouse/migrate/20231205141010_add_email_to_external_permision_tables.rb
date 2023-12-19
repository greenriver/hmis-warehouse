class AddEmailToExternalPermisionTables < ActiveRecord::Migration[6.1]
  def change
    [
      :external_reporting_project_permissions,
      :external_reporting_cohort_permissions,
    ].each do |table|
      add_column table, :email, :string
    end
  end
end
