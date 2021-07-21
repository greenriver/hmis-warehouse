class AddIndividualToCohortClient < ActiveRecord::Migration[5.2]
  def change
    add_column :cohort_clients, :individual, :boolean
  end
end
