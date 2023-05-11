class AddDaysToReturn < ActiveRecord::Migration[6.1]
  def change
    add_column :system_pathways_clients, :days_to_return, :integer
  end
end
