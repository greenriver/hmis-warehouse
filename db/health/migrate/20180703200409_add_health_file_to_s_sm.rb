class AddHealthFileToSSm < ActiveRecord::Migration
  def change
    add_column :self_sufficiency_matrix_forms, :health_file_id, :integer
  end
end
