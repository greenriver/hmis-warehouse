class RenameSymptomatic < ActiveRecord::Migration[5.2]
  def change
    rename_column :tracing_contacts, :symtomatic, :symptomatic
  end
end
