class BedroomSizeOnCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :minimum_bedroom_size, :integer
    add_column :cohort_clients, :special_needs, :string
  end
end
