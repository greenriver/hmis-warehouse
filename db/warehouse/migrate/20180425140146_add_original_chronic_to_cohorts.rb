class AddOriginalChronicToCohorts < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :original_chronic, :boolean, default: false, null: false
    add_column :cohort_clients, :not_a_vet, :string
  end
end
