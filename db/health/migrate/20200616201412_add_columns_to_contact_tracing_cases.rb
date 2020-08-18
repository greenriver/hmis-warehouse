class AddColumnsToContactTracingCases < ActiveRecord::Migration[5.2]
  def change
    add_column :tracing_cases, :symptoms, :jsonb
    add_column :tracing_cases, :other_symptoms, :string
  end
end
