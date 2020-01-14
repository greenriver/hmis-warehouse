class AddHealthFileToSSm < ActiveRecord::Migration[4.2]
  def change
    add_column :self_sufficiency_matrix_forms, :health_file_id, :integer
  end
end
