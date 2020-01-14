class AddCollectionLocationToSelfSufficiencyMatrixForms < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :self_sufficiency_matrix_forms, :collection_location, :string
  end
end
