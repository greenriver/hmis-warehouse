class AddCollectionLocationToSelfSufficiencyMatrixForms < ActiveRecord::Migration
  def change
    add_column :self_sufficiency_matrix_forms, :collection_location, :string
  end
end
