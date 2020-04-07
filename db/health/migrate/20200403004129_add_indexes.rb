class AddIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :tracing_cases, [:first_name, :last_name]
    add_index :tracing_contacts, [:first_name, :last_name]
  end
end
