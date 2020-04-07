class AddDay2 < ActiveRecord::Migration[5.2]
  def change
    add_column :tracing_cases, :day_two, :date
    add_column :tracing_cases, :phone, :string
    add_column :tracing_contacts, :notified, :string
    add_column :tracing_staffs, :notified, :string
    add_index :tracing_cases, :aliases
    add_index :tracing_contacts, :aliases
  end
end
