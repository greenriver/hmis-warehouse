class ChangeTracingAliasesType < ActiveRecord::Migration[5.2]
  def change
    change_column :tracing_cases, :aliases, :string
    change_column :tracing_contacts, :aliases, :string
  end
end
