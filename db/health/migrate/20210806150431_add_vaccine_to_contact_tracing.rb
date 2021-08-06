class AddVaccineToContactTracing < ActiveRecord::Migration[5.2]
  def change
    [
      :tracing_cases,
      :tracing_contacts,
      :tracing_staffs,
    ].each do |table|
      add_column table, :vaccinated, :string
      add_column table, :vaccine, :jsonb
      add_column table, :vaccination_dates, :jsonb
      add_column table, :vaccination_complete, :string
    end
  end
end
