class AddReportingPeriodToCustomServices < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_imports_b_services_rows, :reporting_period_started_on, :date
    add_column :custom_imports_b_services_rows, :reporting_period_ended_on, :date
    add_column :generic_services, :data_source_id, :integer
    add_column :generic_services, :category, :string
  end
end
