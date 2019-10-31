class AddMedicaidIdToPatients < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :patients, :medicaid_id, :string
  end
end
